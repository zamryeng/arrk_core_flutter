import 'package:go_router/go_router.dart';

import 'arrk_route.dart';

/// One deep link: an externally-shared URL pattern that redirects into an
/// in-app route.
///
/// Deep links never build screens — they translate an inbound URI into the
/// canonical route (usually carrying the path segments over as query
/// parameters) and let the normal router take it from there. The product
/// declares its links and aggregates [toGoRoute] results into its top-level
/// route table:
///
/// ```dart
/// static final serviceShare = DeepLinkRoute(
///   route: ArrkRoute(name: 'deep-link-service-share', path: '/share/service/:country/:provider'),
///   redirect: (state) => Uri(
///     path: DashboardRouter.dashboardRoute.path,
///     queryParameters: {
///       'preSelectCountry': state.pathParameters['country']!,
///       'preSelectProvider': state.pathParameters['provider']!,
///     },
///   ).toString(),
/// );
///
/// // In the product's route aggregator:
/// routes: [...featureRoutes, serviceShare.toGoRoute()],
/// ```
class DeepLinkRoute {
  DeepLinkRoute({required this.route, required this.redirect});

  /// The link's own name + URL pattern (path parameters allowed).
  final ArrkRoute route;

  /// Maps the matched inbound state to the destination location string.
  final String Function(GoRouterState state) redirect;

  /// The GoRouter redirect entry for this link.
  RouteBase toGoRoute() => GoRoute(
    path: route.path,
    name: route.name,
    redirect: (context, state) => redirect(state),
  );
}
