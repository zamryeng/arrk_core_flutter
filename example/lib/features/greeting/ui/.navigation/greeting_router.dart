import 'package:arrk_core_flutter/locator.dart';
import 'package:arrk_core_flutter/navigation.dart';
import 'package:go_router/go_router.dart';

import '../../domain/dtos/greeting_draft_dto.dart';
import '../compose_greeting_view.dart';
import '../preview_greeting_view.dart';

/// The greeting feature's router: routes aggregated by the app router,
/// typed verb methods callable context-free from views. View models never
/// navigate.
final class GreetingRouter {
  GreetingRouter._();

  static const composeRoute = ArrkRoute(name: 'compose-greeting', path: '/');
  static const previewRoute = ArrkRoute(name: 'preview-greeting', path: '/preview');

  static List<RouteBase> get routes => [
    GoRoute(
      path: composeRoute.path,
      name: composeRoute.name,
      builder: (context, state) => const ComposeGreetingView(),
    ),
    GoRoute(
      path: previewRoute.path,
      name: previewRoute.name,
      builder: (context, state) => PreviewGreetingView(
        vm: ServiceLocator.get(param1: state.extra! as GreetingDraftDto),
      ),
    ),
  ];

  static void preview(GreetingDraftDto draft) =>
      ArrkNavigator.main.push(previewRoute, extra: draft);

  static void backToCompose() => ArrkNavigator.main.pop();
}
