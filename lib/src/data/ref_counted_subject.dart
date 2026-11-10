import 'dart:async';

import 'package:rxdart/rxdart.dart';

/// Marks a cleared slot in [RefCountedSubject].
const Object _cleared = _Cleared();

class _Cleared {
  const _Cleared();
}

/// A [BehaviorSubject] wrapper that tracks subscriber count and fires
/// edge callbacks when the count transitions through zero.
///
/// `onFirstListen` fires when listener count goes 0 → 1.
/// `onLastCancel` fires when listener count goes 1 → 0.
///
/// Used by [CachedStream] to drive demand-driven hydration and refresh:
/// no subscribers means no work. Package-internal — not exported.
class RefCountedSubject<T> {
  RefCountedSubject({this._onFirstListen, this._onLastCancel}) {
    _subject = BehaviorSubject<Object?>(
      onListen: _handleListen,
      onCancel: _handleCancel,
    );
  }

  /// Holds either a `T` or [_cleared]. Typed `Object?` so a cleared slot
  /// can replay "nothing" without closing the subject.
  late final BehaviorSubject<Object?> _subject;
  final void Function()? _onFirstListen;
  final void Function()? _onLastCancel;
  int _listenerCount = 0;

  /// Values only. After [clear], a new listener gets no replay.
  Stream<T> get stream => _subject.stream.where(_isValue).cast<T>();

  T? get valueOrNull => hasValue ? _subject.value as T : null;
  bool get hasValue => _subject.hasValue && _isValue(_subject.value);
  bool get isClosed => _subject.isClosed;

  /// Whether the subject currently has a subscriber.
  ///
  /// [BehaviorSubject] only fires `onListen`/`onCancel` on the 0→1 and 1→0
  /// edges, so the tracked count is effectively pinned to 0 or 1. This exposes
  /// that as a boolean to avoid implying a precise multi-listener count.
  bool get hasListener => _listenerCount > 0;

  void add(T value) {
    if (_subject.isClosed) return;
    _subject.add(value);
  }

  /// Drops the held value. Mounted listeners receive nothing; new listeners
  /// get no replay until the next [add].
  void clear() {
    if (_subject.isClosed || !hasValue) return;
    _subject.add(_cleared);
  }

  Future<void> close() => _subject.close();

  static bool _isValue(Object? v) => !identical(v, _cleared);

  void _handleListen() {
    _listenerCount++;
    if (_listenerCount == 1) _onFirstListen?.call();
  }

  FutureOr<void> _handleCancel() {
    if (_listenerCount > 0) _listenerCount--;
    if (_listenerCount == 0) _onLastCancel?.call();
  }
}
