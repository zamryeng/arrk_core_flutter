import 'dart:async';

import 'package:arrk_core_flutter/navigation.dart';
import 'package:arrk_core_flutter/view.dart';
import 'package:arrk_core_flutter/viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

/// The app's one message reader. Draws each message as a toast on the root
/// navigator's overlay, so it sits above every route and sheet — never in
/// a `Scaffold`, where a modal sheet could cover it.
@singleton
class OverlayMessageHandler extends ArrkMessageHandler {
  OverlayMessageHandler(super.messages);

  static const _visibleFor = Duration(seconds: 3);

  @override
  void show(UserMessage message) {
    final overlay = ArrkNavigator.mainNavigatorKey.currentState?.overlay;
    if (overlay == null) return; // nothing mounted yet
    final entry = OverlayEntry(builder: (context) => _Toast(message: message));
    overlay.insert(entry);
    Timer(_visibleFor, entry.remove);
  }
}

class _Toast extends StatelessWidget {
  const _Toast({required this.message});

  final UserMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (message.kind) {
      UserMessageKind.error => (scheme.error, scheme.onError),
      UserMessageKind.success => (scheme.primary, scheme.onPrimary),
      UserMessageKind.warning => (scheme.tertiary, scheme.onTertiary),
      UserMessageKind.info => (scheme.inverseSurface, scheme.onInverseSurface),
    };
    final heading = message.heading;
    return Positioned(
      left: 16,
      right: 16,
      bottom: 32,
      child: SafeArea(
        child: Material(
          color: background,
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              heading == null ? message.text : '$heading — ${message.text}',
              style: TextStyle(color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}
