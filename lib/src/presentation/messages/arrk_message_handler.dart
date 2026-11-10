import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../data/clock.dart';
import '../../domain/messages/user_message.dart';
import '../../domain/messages/user_message_kind.dart';
import 'message_stream.dart';

/// The app's one message reader: subscribes to [MessageStream] and draws
/// each message through [show].
///
/// Rules:
/// - **Messages outlive their screen.** A message is shown even when the
///   view model that pushed it is disposed, or sits on a screen that is not
///   visible (a tab behind another tab). A send that finishes after the
///   user went back still reports its result.
/// - **Duplicates merge.** A message with the same `kind` and `text` as one
///   shown within [dedupeWindow] is skipped. This is what keeps hidden
///   screens from becoming noise.
/// - **A throwing [show] is logged**, and later messages are still shown.
///
/// ```dart
/// @singleton
/// class ToastMessageHandler extends ArrkMessageHandler {
///   ToastMessageHandler(super.messages);
///
///   @override
///   void show(UserMessage message) { /* insert an OverlayEntry */ }
/// }
///
/// // main(), after DI:
/// ServiceLocator.get<ToastMessageHandler>().start();
/// ```
abstract class ArrkMessageHandler {
  ArrkMessageHandler(this._messages, {this.dedupeWindow = const Duration(seconds: 2), Clock? clock})
    : _clock = clock ?? Clock.current;

  final MessageStream _messages;
  final Clock _clock;

  /// How long an identical message (same kind and text) is suppressed after
  /// one is shown.
  final Duration dedupeWindow;

  StreamSubscription<UserMessage>? _subscription;
  final Map<(UserMessageKind, String), DateTime> _lastShown = <(UserMessageKind, String), DateTime>{};

  static final Logger _logger = Logger('ArrkMessageHandler');

  /// Whether [start] has run and [dispose] has not.
  bool get isStarted => _subscription != null;

  /// Subscribes to the channel. Calling it again while started does nothing.
  void start() {
    _subscription ??= _messages.messages.listen(_handle);
  }

  /// Draws [message].
  ///
  /// Draw on the **root overlay**, above every route and sheet (for example
  /// an `OverlayEntry` in the root navigator's overlay). Do not draw in a
  /// `Scaffold`: a modal sheet can cover a Scaffold's snackbar.
  @protected
  void show(UserMessage message);

  /// Cancels the subscription. Messages pushed afterwards are not shown.
  Future<void> dispose() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }

  void _handle(UserMessage message) {
    final now = _clock.now();
    _lastShown.removeWhere((_, shownAt) => now.difference(shownAt) >= dedupeWindow);
    final key = (message.kind, message.text);
    if (_lastShown.containsKey(key)) return;
    _lastShown[key] = now;
    try {
      show(message);
    } catch (error, stackTrace) {
      _logger.severe('show($message) threw; continuing', error, stackTrace);
    }
  }
}
