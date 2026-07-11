import 'dart:async';

import '../domain/arrk_responses.dart';
import '../domain/failure.dart';
import 'arrk_exceptions.dart';
import 'clock.dart';
import 'ref_counted_subject.dart';

/// A demand-driven cache around a single value of type [T].
///
/// Composed by repos (never inherited from). The repo holds private
/// [CachedStream] instances and exposes a hand-written, domain-named API
/// over them.
///
/// Behavior:
/// - On first subscribe: hydrates from [readLocal] (if present), emitting
///   the cached value. Then, if [isStale], triggers a remote refresh.
/// - On stale + subscribed: refresh runs. Concurrent subscribers share the
///   in-flight future.
/// - On no subscribers: goes quiet. No background work.
/// - On [refresh]: runs [fetchRemote], writes via [writeLocal], emits.
///   Returns a [DataResponse] (typed [Failure] on error, never throws).
/// - On [invalidate]: marks stale. Next subscribe triggers refresh.
///
/// Time is read via [Clock.current] by default. Tests may pass an explicit
/// [Clock] to isolate from ambient state.
class CachedStream<T> {
  CachedStream({
    required this.ttl,
    required this.cacheKey,
    required Future<T?> Function() readLocal,
    required Future<T> Function() fetchRemote,
    required Future<void> Function(T value) writeLocal,
    Clock? clock,
  }) : _readLocal = readLocal,
       _fetchRemote = fetchRemote,
       _writeLocal = writeLocal,
       _clock = clock ?? Clock.current {
    _subject = RefCountedSubject<T>(
      onFirstListen: _handleFirstListen,
      onLastCancel: _handleLastCancel,
    );
  }

  final Duration ttl;
  final String cacheKey;
  final Future<T?> Function() _readLocal;
  final Future<T> Function() _fetchRemote;
  final Future<void> Function(T value) _writeLocal;
  final Clock _clock;

  late final RefCountedSubject<T> _subject;
  DateTime? _lastFetchedAt;
  Future<DataResponse<T>>? _pendingRefresh;
  bool _hydrated = false;

  /// The broadcast stream of cached values. Subscribe to receive the
  /// current cached value (if any) and all subsequent emissions.
  Stream<T> get stream => _subject.stream;

  /// The most recently emitted value, or null if none yet.
  T? get current => _subject.valueOrNull;

  /// True if a remote refresh has never succeeded, or if the last successful
  /// fetch is older than [ttl] from [Clock.current].now().
  bool get isStale {
    final last = _lastFetchedAt;
    if (last == null) return true;
    return _clock.now().difference(last) >= ttl;
  }

  /// Forces a remote refresh. Concurrent callers share the in-flight future.
  ///
  /// Never throws — errors are wrapped into [DataResponse.error]. On success,
  /// the new value is written via [writeLocal] and emitted on [stream].
  Future<DataResponse<T>> refresh() {
    final pending = _pendingRefresh;
    if (pending != null) return pending;
    final tracked = _runRefresh().whenComplete(() => _pendingRefresh = null);
    _pendingRefresh = tracked;
    return tracked;
  }

  /// Marks the cache as stale without clearing the current value. The next
  /// subscriber (or explicit [refresh] call) will trigger a fetch.
  ///
  /// **Does not emit** on the underlying subject — mounted listeners
  /// subscribed via [stream] will NOT receive a notification from
  /// [invalidate] alone. Callers that need to push a fresh value to
  /// already-subscribed consumers must call [refresh] (which emits).
  /// The lazy path exists for reactions to cross-feature events: mark the
  /// cache stale, let the next mounted screen pay for the re-fetch.
  ///
  /// [invalidate] does not participate in the in-flight refresh
  /// de-duplication. If a refresh is in-flight when [invalidate] is called,
  /// the refresh will complete and overwrite `_lastFetchedAt` with the
  /// now-time — losing the invalidation. Callers that invalidate
  /// concurrently with refreshes should reason about this explicitly.
  Future<void> invalidate() async {
    _lastFetchedAt = null;
  }

  /// Optimistically emits [value] to subscribers without persisting it or
  /// touching staleness.
  ///
  /// Use after a local mutation whose true value the network will confirm
  /// (e.g. a just-submitted operation decrementing a balance): the optimistic
  /// value paints immediately, while [isStale] and `writeLocal` are left
  /// untouched so the next [refresh] still reconciles against the source of
  /// truth. A guessed value must never poison the local cache.
  void emitOptimistic(T value) => _subject.add(value);

  /// Closes the underlying subject. After [dispose], the stream is closed
  /// and no further emissions occur.
  Future<void> dispose() => _subject.close();

  Future<DataResponse<T>> _runRefresh() async {
    try {
      final value = await _fetchRemote();
      await _writeLocal(value);
      _lastFetchedAt = _clock.now();
      _subject.add(value);
      return DataResponse<T>(data: value);
    } on ArrkException catch (e) {
      return DataResponse<T>(data: null, error: e.toFailure(), cause: e);
    } on TimeoutException catch (e) {
      return DataResponse<T>(data: null, error: TimeoutFailure(), cause: e);
    } catch (e) {
      return DataResponse<T>(data: null, error: UnknownFailure(), cause: e);
    }
  }

  Future<void> _handleFirstListen() async {
    if (!_hydrated) {
      _hydrated = true;
      try {
        final cached = await _readLocal();
        if (cached != null) _subject.add(cached);
      } catch (_) {
        // Local read failure is non-fatal — refresh will repopulate.
      }
    }
    if (isStale && _subject.hasListener) {
      // Fire-and-forget: the result is delivered via the stream emit;
      // explicit callers use [refresh] directly for the DataResponse.
      unawaited(refresh());
    }
  }

  void _handleLastCancel() {
    // Reserved for future periodic timers / long-running fetches.
    // Current implementation has nothing to cancel.
  }
}
