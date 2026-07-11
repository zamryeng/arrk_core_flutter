import 'package:arrk_core_flutter/navigation.dart';
import 'package:go_router/go_router.dart';

import '../features/greeting/ui/.navigation/greeting_router.dart';
import 'example_extras_codec.dart';

/// Root router: aggregates every feature router's routes. The navigator key
/// makes `ArrkNavigator.main` work anywhere; the extras codec serializes
/// route extras.
final class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: ArrkNavigator.mainNavigatorKey,
    extraCodec: const ExampleExtrasCodec(),
    routes: [
      ...GreetingRouter.routes,
    ],
  );
}
