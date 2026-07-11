import 'package:arrk_core_flutter/viewmodel.dart';
import 'package:flutter/material.dart';

/// [MessageDisplayHandler] over the app's root [ScaffoldMessenger] — the one
/// implementation every `ArrkViewModel` resolves from DI.
class SnackbarMessageHandler implements MessageDisplayHandler {
  SnackbarMessageHandler(this._messengerKey);

  final GlobalKey<ScaffoldMessengerState> _messengerKey;

  void _show(String message, {String? heading, bool isError = false}) {
    final messenger = _messengerKey.currentState;
    if (messenger == null) return;
    final theme = Theme.of(_messengerKey.currentContext!);
    messenger.showSnackBar(
      SnackBar(
        content: Text(heading == null ? message : '$heading — $message'),
        backgroundColor: isError ? theme.colorScheme.error : null,
      ),
    );
  }

  @override
  void showError(String message, [String? heading]) =>
      _show(message, heading: heading, isError: true);

  @override
  void showSuccess(String message, [String? heading]) => _show(message, heading: heading);

  @override
  void showWarning(String message, [String? heading]) => _show(message, heading: heading);

  @override
  void showInfo(String message, [String? heading]) => _show(message, heading: heading);
}
