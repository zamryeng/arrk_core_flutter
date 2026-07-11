import 'package:flutter/material.dart';

import 'navigation/app_router.dart';

/// Root messenger key: the [SnackbarMessageHandler] shows VM messages
/// through it.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'arrk_core_flutter example',
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF01614B), useMaterial3: true),
      routerConfig: AppRouter.router,
    );
  }
}
