import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:arrk_core_flutter/data.dart';
import 'package:arrk_core_flutter/responses.dart';
import 'package:arrk_core_flutter/testing.dart';

class _BoomException implements Exception {
  const _BoomException();
}

/// Helpers that build a [CachedStream] with controllable backing functions.
class _Harness<T> {
  _Harness({
    T? initialLocal,
    this.ttl = const Duration(seconds: 30),
    Clock? clock,
  }) : _local = initialLocal,
       clock = clock ?? FakeClock() {
    stream = CachedStream<T>(
      ttl: ttl,
      cacheKey: 'k',
      readLocal: () async {
        readLocalCalls++;
        final override = onReadLocal;
        if (override != null) return override();
        return _local;
      },
      fetchRemote: () async {
        fetchRemoteCalls++;
        final delegate = onFetch;
        if (delegate == null) {
          throw StateError('onFetch not configured for harness');
        }
        return delegate();
      },
      writeLocal: (value) async {
        writeLocalCalls++;
        _local = value;
      },
      clock: this.clock,
    );
  }

  final Duration ttl;
  final Clock clock;
  late final CachedStream<T> stream;

  T? _local;
  int readLocalCalls = 0;
  int fetchRemoteCalls = 0;
  int writeLocalCalls = 0;
  Future<T> Function()? onFetch;

  /// Overrides the default [readLocal] body when set (e.g. to throw).
  Future<T?> Function()? onReadLocal;

  T? get local => _local;
}

void main() {
  // Snapshot + restore ambient clock so tests don't leak.
  late Clock originalAmbient;
  setUp(() => originalAmbient = Clock.current);
  tearDown(() => Clock.current = originalAmbient);

  group('CachedStream — hydration', () {
    test('isStale is true before any fetch', () {
      final h = _Harness<int>();
      expect(h.stream.isStale, isTrue);
      expect(h.stream.current, isNull);
    });

    test('emits cached local value on first subscribe', () async {
      final h = _Harness<int>(initialLocal: 42)..onFetch = () async => 99;

      final emitted = <int>[];
      final sub = h.stream.stream.listen(emitted.add);

      // Let microtasks run so readLocal completes and emit propagates.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(emitted.first, 42);
      expect(h.readLocalCalls, 1);
      await sub.cancel();
    });

    test('hydrates only once across resubscribes', () async {
      final h = _Harness<int>(initialLocal: 1)..onFetch = () async => 1;

      final sub1 = h.stream.stream.listen((_) {});
      await Future<void>.delayed(Duration.zero);
      await sub1.cancel();

      final sub2 = h.stream.stream.listen((_) {});
      await Future<void>.delayed(Duration.zero);

      expect(h.readLocalCalls, 1);
      await sub2.cancel();
    });
  });

  group('CachedStream — refresh on stale', () {
    test('triggers fetchRemote on first subscribe when stale', () async {
      final h = _Harness<int>()..onFetch = () async => 7;

      final sub = h.stream.stream.listen((_) {});
      // Allow fire-and-forget refresh to complete.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(h.fetchRemoteCalls, 1);
      expect(h.writeLocalCalls, 1);
      expect(h.local, 7);
      await sub.cancel();
    });

    test('does not fetch when fresh', () async {
      final h = _Harness<int>(initialLocal: 5)..onFetch = () async => 5;

      // Prime: refresh once so _lastFetchedAt is set.
      final res = await h.stream.refresh();
      expect(res.isSuccessful, isTrue);
      expect(h.fetchRemoteCalls, 1);

      // Now subscribe — still fresh, no new fetch.
      final sub = h.stream.stream.listen((_) {});
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(h.fetchRemoteCalls, 1);
      await sub.cancel();
    });

    test('refetches after TTL elapses', () async {
      final clock = FakeClock();
      final h = _Harness<int>(
        ttl: const Duration(seconds: 30),
        clock: clock,
      )..onFetch = () async => 1;

      await h.stream.refresh();
      expect(h.fetchRemoteCalls, 1);
      expect(h.stream.isStale, isFalse);

      clock.advance(const Duration(seconds: 31));
      expect(h.stream.isStale, isTrue);

      h.onFetch = () async => 2;
      await h.stream.refresh();
      expect(h.fetchRemoteCalls, 2);
      expect(h.stream.current, 2);
    });
  });

  group('CachedStream — concurrent refresh', () {
    test('shares in-flight future across concurrent callers', () async {
      final completer = Completer<int>();
      final h = _Harness<int>()..onFetch = () => completer.future;

      final f1 = h.stream.refresh();
      final f2 = h.stream.refresh();

      expect(identical(f1, f2), isTrue);
      completer.complete(123);

      final r1 = await f1;
      final r2 = await f2;
      expect(r1.data, 123);
      expect(r2.data, 123);
      expect(h.fetchRemoteCalls, 1);
    });

    test('allows new fetch after in-flight completes', () async {
      final h = _Harness<int>()..onFetch = () async => 1;
      await h.stream.refresh();
      h.onFetch = () async => 2;
      await h.stream.refresh();
      expect(h.fetchRemoteCalls, 2);
    });
  });

  group('CachedStream — error wrapping', () {
    test('returns UnknownFailure for unexpected throw', () async {
      final h = _Harness<int>()..onFetch = () async => throw const _BoomException();

      final res = await h.stream.refresh();
      expect(res.hasError, isTrue);
      expect(res.error, isA<UnknownFailure>());
      expect(res.cause, isA<_BoomException>());
    });

    test('wraps TimeoutException as TimeoutFailure', () async {
      final h = _Harness<int>()..onFetch = () async => throw TimeoutException('slow');

      final res = await h.stream.refresh();
      expect(res.error, isA<TimeoutFailure>());
      expect(res.cause, isA<TimeoutException>());
    });

    test('preserves current value when refresh fails', () async {
      final h = _Harness<int>()..onFetch = () async => 10;
      await h.stream.refresh();
      expect(h.stream.current, 10);

      h.onFetch = () async => throw const _BoomException();
      final res = await h.stream.refresh();
      expect(res.hasError, isTrue);
      expect(h.stream.current, 10);
    });
  });

  group('CachedStream — invalidate', () {
    test('marks cache stale without clearing current', () async {
      final h = _Harness<int>()..onFetch = () async => 1;
      await h.stream.refresh();
      expect(h.stream.isStale, isFalse);

      await h.stream.invalidate();
      expect(h.stream.isStale, isTrue);
      expect(h.stream.current, 1);
    });

    test('next subscribe after invalidate triggers refresh', () async {
      final h = _Harness<int>()..onFetch = () async => 1;
      await h.stream.refresh();
      await h.stream.invalidate();

      h.onFetch = () async => 2;
      final sub = h.stream.stream.listen((_) {});
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(h.fetchRemoteCalls, 2);
      expect(h.stream.current, 2);
      await sub.cancel();
    });

    test('invalidate does NOT emit to already-subscribed listeners', () async {
      final h = _Harness<int>()..onFetch = () async => 1;
      await h.stream.refresh();

      final emissions = <int>[];
      final sub = h.stream.stream.listen(emissions.add);
      // Settle hydrate + replay microtasks.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final baselineLen = emissions.length;
      final baselineFetches = h.fetchRemoteCalls;

      await h.stream.invalidate();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // Mounted subscriber sees no new emission and no new fetch.
      expect(emissions.length, baselineLen);
      expect(h.fetchRemoteCalls, baselineFetches);

      await sub.cancel();
    });

    test('refresh DOES emit to already-subscribed listeners', () async {
      final h = _Harness<int>()..onFetch = () async => 1;
      await h.stream.refresh();

      final emissions = <int>[];
      final sub = h.stream.stream.listen(emissions.add);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final baselineLen = emissions.length;

      h.onFetch = () async => 2;
      await h.stream.refresh();
      await Future<void>.delayed(Duration.zero);

      // Mounted subscriber receives the refreshed value via subject emission.
      expect(emissions.length, greaterThan(baselineLen));
      expect(emissions.last, 2);

      await sub.cancel();
    });
  });

  group('CachedStream — quiet without subscribers', () {
    test('does no work until first subscribe', () async {
      final h = _Harness<int>(initialLocal: 1)..onFetch = () async => 2;
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(h.readLocalCalls, 0);
      expect(h.fetchRemoteCalls, 0);
    });

    test('dispose closes the stream', () async {
      final h = _Harness<int>()..onFetch = () async => 1;
      await h.stream.dispose();

      // Subsequent emit attempts are silently ignored (no throw).
      await h.stream.refresh();
    });
  });

  group('CachedStream — demand-driven refresh (hasListener path)', () {
    test('concurrent subscribers share a single refresh', () async {
      final completer = Completer<int>();
      final h = _Harness<int>()..onFetch = () => completer.future;

      // Two subscribers attach while stale. The subject only fires onListen on
      // the 0->1 edge, so exactly one demand-driven refresh should kick off.
      final subA = h.stream.stream.listen((_) {});
      final subB = h.stream.stream.listen((_) {});
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      completer.complete(7);
      await Future<void>.delayed(Duration.zero);

      expect(h.fetchRemoteCalls, 1);
      expect(h.writeLocalCalls, 1);
      await subA.cancel();
      await subB.cancel();
    });

    test('ref-count dropping to 0 then resubscribing re-triggers refresh', () async {
      final clock = FakeClock();
      final h = _Harness<int>(ttl: const Duration(seconds: 30), clock: clock)
        ..onFetch = () async => 1;

      final sub1 = h.stream.stream.listen((_) {});
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(h.fetchRemoteCalls, 1);

      // Drop to zero listeners, then go stale again.
      await sub1.cancel();
      clock.advance(const Duration(seconds: 31));
      expect(h.stream.isStale, isTrue);

      // Resubscribing crosses the 0->1 edge again and re-triggers refresh.
      h.onFetch = () async => 2;
      final sub2 = h.stream.stream.listen((_) {});
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(h.fetchRemoteCalls, 2);
      expect(h.stream.current, 2);
      await sub2.cancel();
    });

    test('a throwing readLocal is non-fatal and refresh still repopulates', () async {
      final h = _Harness<int>()
        ..onReadLocal = (() async => throw const _BoomException())
        ..onFetch = () async => 55;

      final emitted = <int>[];
      final sub = h.stream.stream.listen(emitted.add);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // Hydration threw but was swallowed; the stale refresh repopulated.
      expect(h.readLocalCalls, 1);
      expect(h.fetchRemoteCalls, 1);
      expect(emitted, contains(55));
      expect(h.stream.current, 55);
      await sub.cancel();
    });
  });

  group('CachedStream — emitOptimistic', () {
    test('pushes the value to current subscribers', () async {
      final h = _Harness<int>()..onFetch = () async => 1;
      // Prime to fresh so subscribing does not trigger a refresh.
      await h.stream.refresh();

      final emitted = <int>[];
      final sub = h.stream.stream.listen(emitted.add);
      await Future<void>.delayed(Duration.zero); // settle replay + hydration

      h.stream.emitOptimistic(99);
      await Future<void>.delayed(Duration.zero);

      expect(emitted.last, 99);
      expect(h.stream.current, 99);
      await sub.cancel();
    });

    test('updates current without clearing staleness', () {
      final h = _Harness<int>();
      expect(h.stream.isStale, isTrue);

      h.stream.emitOptimistic(5);

      expect(h.stream.current, 5);
      // Optimistic emits are guesses — they must not mark the cache fresh.
      expect(h.stream.isStale, isTrue);
    });

    test('does not write to the local cache', () {
      final h = _Harness<int>();

      h.stream.emitOptimistic(7);

      expect(h.writeLocalCalls, 0);
      expect(h.local, isNull);
    });
  });

  group('Clock', () {
    test('SystemClock returns close-to-real now', () {
      final before = DateTime.now();
      final c = const SystemClock().now();
      final after = DateTime.now();
      expect(c.isBefore(before), isFalse);
      expect(c.isAfter(after), isFalse);
    });

    test('Clock.current defaults to SystemClock and is reassignable', () {
      expect(Clock.current, isA<SystemClock>());
      final fake = FakeClock(DateTime(2026, 6, 11));
      Clock.current = fake;
      expect(Clock.current.now(), DateTime(2026, 6, 11));
    });

    test('CachedStream falls back to ambient Clock.current when none passed', () async {
      final ambient = FakeClock(DateTime(2026, 1, 1));
      Clock.current = ambient;

      final stream = CachedStream<int>(
        ttl: const Duration(seconds: 10),
        cacheKey: 'k',
        readLocal: () async => null,
        fetchRemote: () async => 1,
        writeLocal: (_) async {},
      );

      await stream.refresh();
      expect(stream.isStale, isFalse);

      ambient.advance(const Duration(seconds: 11));
      expect(stream.isStale, isTrue);
    });
  });

  group('FakeClock', () {
    test('starts at 2026-01-01 by default', () {
      final c = FakeClock();
      expect(c.now(), DateTime(2026, 1, 1));
    });

    test('advance moves time forward', () {
      final c = FakeClock(DateTime(2026, 1, 1));
      c.advance(const Duration(hours: 2));
      expect(c.now(), DateTime(2026, 1, 1, 2));
    });

    test('setTo jumps to an absolute instant', () {
      final c = FakeClock();
      final target = DateTime(2030, 6, 15);
      c.setTo(target);
      expect(c.now(), target);
    });
  });
}
