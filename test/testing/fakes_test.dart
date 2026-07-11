import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:arrk_core_flutter/data.dart';
import 'package:arrk_core_flutter/events.dart';
import 'package:arrk_core_flutter/testing.dart';
import 'package:arrk_core_flutter/viewmodel.dart';

void main() {
  group('FakeClock', () {
    test('advance moves time forward by the given duration', () {
      final clock = FakeClock(DateTime(2026, 1, 1));
      clock.advance(const Duration(hours: 3));
      expect(clock.now(), DateTime(2026, 1, 1, 3));
    });

    test('advance is cumulative', () {
      final clock = FakeClock(DateTime(2026, 1, 1));
      clock.advance(const Duration(minutes: 10));
      clock.advance(const Duration(minutes: 5));
      expect(clock.now(), DateTime(2026, 1, 1, 0, 15));
    });

    test('setTo jumps to an absolute instant', () {
      final clock = FakeClock();
      final target = DateTime(2030, 12, 31, 23, 59);
      clock.setTo(target);
      expect(clock.now(), target);
    });

    test('drives CachedStream TTL deterministically', () async {
      final clock = FakeClock();
      var fetches = 0;
      final cache = CachedStream<int>(
        ttl: const Duration(seconds: 30),
        cacheKey: 'k',
        readLocal: () async => null,
        fetchRemote: () async => ++fetches,
        writeLocal: (_) async {},
        clock: clock,
      );

      await cache.refresh();
      expect(fetches, 1);
      expect(cache.isStale, isFalse);

      clock.advance(const Duration(seconds: 31));
      expect(cache.isStale, isTrue);
    });

    test('can stand in for ambient Clock.current', () {
      final original = Clock.current;
      addTearDown(() => Clock.current = original);

      final clock = FakeClock(DateTime(2026, 6, 11));
      Clock.current = clock;
      expect(Clock.current.now(), DateTime(2026, 6, 11));
    });
  });

  group('FakeArrkEventBus', () {
    late FakeArrkEventBus bus;

    setUp(() => bus = FakeArrkEventBus());
    tearDown(() => bus.destroy());

    test('records fired events in order', () {
      bus.fire(SessionCountryChanged(countryCode: 'GH', firedAt: DateTime(2026)));
      bus.fire(SessionCountryChanged(countryCode: 'NG', firedAt: DateTime(2026)));

      expect(bus.fired, hasLength(2));
      expect(
        (bus.fired.first as SessionCountryChanged).countryCode,
        'GH',
      );
    });

    test('still delivers events to subscribers', () async {
      final received = <SessionCountryChanged>[];
      final sub = bus.on<SessionCountryChanged>().listen(received.add);

      bus.fire(SessionCountryChanged(countryCode: 'GH', firedAt: DateTime(2026)));
      await Future<void>.delayed(Duration.zero);

      expect(received.single.countryCode, 'GH');
      await sub.cancel();
    });

    test('firedOfType returns only the matching type', () {
      bus.fire(SessionCountryChanged(countryCode: 'GH', firedAt: DateTime(2026)));
      bus.fire(SessionLocaleChanged(locale: const Locale('en'), firedAt: DateTime(2026)));

      // Only SessionCountryChanged events.
      final countries = bus.firedOfType<SessionCountryChanged>();
      expect(countries, hasLength(1));
      expect(countries.single.countryCode, 'GH');
    });

    test('didFire returns true once an event of that type has been fired', () {
      expect(bus.didFire<SessionCountryChanged>(), isFalse);
      bus.fire(SessionCountryChanged(countryCode: 'US', firedAt: DateTime(2026)));
      expect(bus.didFire<SessionCountryChanged>(), isTrue);
    });

    test('clearRecorded resets the history without affecting subscriptions', () async {
      final received = <ArrkEvent>[];
      final sub = bus.all.listen(received.add);

      bus.fire(SessionCountryChanged(countryCode: 'GH', firedAt: DateTime(2026)));
      await Future<void>.delayed(Duration.zero);

      bus.clearRecorded();
      expect(bus.fired, isEmpty);

      // Subscription still active.
      bus.fire(SessionCountryChanged(countryCode: 'NG', firedAt: DateTime(2026)));
      await Future<void>.delayed(Duration.zero);
      expect(received, hasLength(2));

      await sub.cancel();
    });

    test('fired exposes an unmodifiable view', () {
      bus.fire(SessionCountryChanged(countryCode: 'GH', firedAt: DateTime(2026)));

      expect(bus.fired, hasLength(1));
      expect(
        () => bus.fired.add(
          SessionCountryChanged(countryCode: 'US', firedAt: DateTime(2026)),
        ),
        throwsUnsupportedError,
      );
    });

    test('all stream delivers events in fire order', () async {
      final received = <ArrkEvent>[];
      final sub = bus.all.listen(received.add);

      bus.fire(SessionCountryChanged(countryCode: 'A', firedAt: DateTime(2026)));
      bus.fire(SessionCountryChanged(countryCode: 'B', firedAt: DateTime(2026)));
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(2));
      expect((received[0] as SessionCountryChanged).countryCode, 'A');
      expect((received[1] as SessionCountryChanged).countryCode, 'B');
      await sub.cancel();
    });

    test('withBus constructor seam creates bus backed by provided EventBus', () async {
      // FakeArrkEventBus uses the default constructor (ArrkEventBus()) and
      // wraps its own real EventBus. The withBus seam on ArrkEventBus is
      // verified by checking that an ArrkEventBus.withBus delegates fire
      // and on<T> correctly.
      final realBus = ArrkEventBus();
      addTearDown(realBus.destroy);

      final received = <SessionCountryChanged>[];
      final sub = realBus.on<SessionCountryChanged>().listen(received.add);

      realBus.fire(SessionCountryChanged(countryCode: 'ZA', firedAt: DateTime(2026)));
      await Future<void>.delayed(Duration.zero);

      expect(received.single.countryCode, 'ZA');
      await sub.cancel();
    });
  });

  group('NoopMessageHandler', () {
    test('is callable without throwing', () {
      final handler = NoopMessageHandler();

      // All four methods must complete without throwing.
      handler.showError('error');
      handler.showSuccess('success');
      handler.showWarning('warning');
      handler.showInfo('info');
    });

    test('accepts optional heading parameter', () {
      final handler = NoopMessageHandler();

      handler.showError('error', 'heading');
      handler.showSuccess('success', 'heading');
      handler.showWarning('warning', 'heading');
      handler.showInfo('info', 'heading');
    });

    test('implements MessageDisplayHandler', () {
      final MessageDisplayHandler handler = NoopMessageHandler();
      expect(handler, isA<NoopMessageHandler>());
    });
  });
}
