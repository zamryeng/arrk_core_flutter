import 'dart:async';

import 'package:rxdart/rxdart.dart';

/// A [BehaviorSubject] wrapper that tracks subscriber count and fires
/// edge callbacks when the count transitions through zero.
///
/// `onFirstListen` fires when listener count goes 0 → 1.
/// `onLastCancel` fires when listener count goes 1 → 0.
///
/// Used by [CachedStream] to drive demand-driven hydration and refresh:
/// no subscribers means no work. Package-internal — not exported.
class RefCountedSubject<T> {
  RefCountedSubject({
    void Function()? onFirstListen,
    void Function()? onLastCancel,
  }) : _onFirstListen = onFirstListen,
       _onLastCancel = onLastCancel {
    _subject = BehaviorSubject<T>(
      onListen: _handleListen,
      onCancel: _handleCancel,
    );
  }

  late final BehaviorSubject<T> _subject;
  final void Function()? _onFirstListen;
  final void Function()? _onLastCancel;
  int _listenerCount = 0;

  Stream<T> get stream => _subject.stream;
  T? get valueOrNull => _subject.valueOrNull;
  bool get hasValue => _subject.hasValue;
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

  Future<void> close() => _subject.close();

  void _handleListen() {
    _listenerCount++;
    if (_listenerCount == 1) _onFirstListen?.call();
  }

  FutureOr<void> _handleCancel() {
    if (_listenerCount > 0) _listenerCount--;
    if (_listenerCount == 0) _onLastCancel?.call();
  }
}
