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
/// - On [clear]: drops the value, marks stale, deletes the local copy via
///   [clearLocal]. A fetch started before the clear never lands.
///
/// Failures reach callers through [refresh], which returns a [DataResponse].
/// A screen that must show a failed load calls [refresh] and handles the
/// response; it does not rely on the fetch the first listen starts.
///
/// Time is read via [Clock.current] by default. Tests may pass an explicit
/// [Clock] to isolate from ambient state.
class CachedStream<T> {
  CachedStream({
    required this.ttl,
    required this.cacheKey,
    required this._readLocal,
    required this._fetchRemote,
    required this._writeLocal,
    required this._clearLocal,
    Clock? clock,
  }) : _clock = clock ?? Clock.current {
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
  final Future<void> Function() _clearLocal;
  final Clock _clock;

  late final RefCountedSubject<T> _subject;
  DateTime? _lastFetchedAt;
  Future<DataResponse<T>>? _pendingRefresh;
  bool _hydrated = false;

  /// Bumped by [clear]. Work that started under an older generation must not
  /// store, persist or emit anything.
  int _clearGeneration = 0;

  /// Bumped by [invalidate] and [clear]. A refresh that started under an
  /// older generation may store its value but must not mark the cache fresh.
  int _staleGeneration = 0;

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
  ///
  /// If [clear] runs while this refresh is in flight, the fetched value is
  /// still returned to this caller, but it is not written, not emitted and
  /// does not mark the cache fresh.
  Future<DataResponse<T>> refresh() {
    final pending = _pendingRefresh;
    if (pending != null) return pending;
    late final Future<DataResponse<T>> tracked;
    tracked = _runRefresh().whenComplete(() {
      // A clear() may have dropped this refresh and a newer one may own
      // the slot now; only release it if it is still ours.
      if (identical(_pendingRefresh, tracked)) _pendingRefresh = null;
    });
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
  /// If a refresh is in flight, it still stores and emits its value, but
  /// the cache stays stale.
  Future<void> invalidate() async {
    _staleGeneration++;
    _lastFetchedAt = null;
  }

  /// Drops the cache, for sign-out or any change of whose data this is.
  ///
  /// After [clear]: [current] is null, [isStale] is true, the local copy is
  /// deleted via [clearLocal], and the next first listen hydrates again. A
  /// new listener on [stream] gets no replay of the old value. A refresh
  /// that started before the clear does not write, emit or mark the cache
  /// fresh; the next [refresh] starts a new fetch.
  ///
  /// Mounted listeners get no signal: [stream] carries values only. Tear
  /// down or refresh the screens that showed the old value.
  ///
  /// Throws what [clearLocal] throws, so a sign-out can tell that the local
  /// copy survived.
  Future<void> clear() async {
    _clearGeneration++;
    _staleGeneration++;
    _lastFetchedAt = null;
    _pendingRefresh = null;
    _hydrated = false;
    _subject.clear();
    await _clearLocal();
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
    final clearGeneration = _clearGeneration;
    final staleGeneration = _staleGeneration;
    try {
      final value = await _fetchRemote();
      if (clearGeneration != _clearGeneration) return DataResponse<T>(data: value);
      await _writeLocal(value);
      if (clearGeneration != _clearGeneration) return DataResponse<T>(data: value);
      if (staleGeneration == _staleGeneration) _lastFetchedAt = _clock.now();
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
      final clearGeneration = _clearGeneration;
      try {
        final cached = await _readLocal();
        if (cached != null && clearGeneration == _clearGeneration) _subject.add(cached);
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
