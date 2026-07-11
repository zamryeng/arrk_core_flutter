import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import 'arrk_route.dart';

/// Navigation wrapper over GoRouter: one API for routes, dialogs, and
/// bottom sheets.
///
/// Views and view models navigate through [ArrkNavigator.main] (backed by
/// [mainNavigatorKey], which the product hands to its `GoRouter`
/// configuration) — never through raw `context.go*` calls, so navigation
/// stays loggable and testable.
class ArrkNavigator {
  ArrkNavigator.of(this._navigationContext);
  ArrkNavigator.ofKey(GlobalKey<NavigatorState> mainNavigatorKey)
    : _navigationContext = mainNavigatorKey.currentContext!;
  final BuildContext _navigationContext;

  static final ArrkNavigator main = ArrkNavigator.ofKey(mainNavigatorKey);
  static final GlobalKey<NavigatorState> mainNavigatorKey = GlobalKey<NavigatorState>();

  BuildContext get currentContext => _navigationContext;
  bool get canPop => _navigationContext.canPop();

  // ===== ROUTE-BASED NAVIGATION =====

  void go(ArrkRoute route, {Object? extra}) {
    _logNavigation('go', route);
    _navigationContext.goNamed(
      route.name,
      queryParameters: route.queryParameters,
      pathParameters: route.pathParameters,
      extra: extra,
    );
  }

  Future<T?> push<T extends Object?>(ArrkRoute route, {Object? extra}) {
    _logNavigation('push', route);
    return _navigationContext.pushNamed<T>(
      route.name,
      queryParameters: route.queryParameters,
      pathParameters: route.pathParameters,
      extra: extra,
    );
  }

  void pushReplacement(ArrkRoute route, {Object? extra}) {
    _logNavigation('replacement', route);
    _navigationContext.pushReplacementNamed(
      route.name,
      queryParameters: route.queryParameters,
      pathParameters: route.pathParameters,
      extra: extra,
    );
  }

  /// Pop the current route.
  void pop([Object? result]) {
    _logNavigation('pop', 'current');
    _navigationContext.pop(result);
  }

  /// Pop the current route if possible; returns whether a pop happened.
  Future<bool> maybePop([Object? result]) async {
    if (_navigationContext.canPop()) {
      _logNavigation('pop', 'current');
      _navigationContext.pop(result);
      return true;
    }
    return false;
  }

  // ===== DIALOG AND BOTTOM SHEET =====

  /// Open a dialog.
  Future<T?> openDialog<T>({
    required Widget dialog,
    String? routeName,
    bool barrierDismissable = true,
    BuildContext? context,
  }) {
    context ??= _navigationContext;
    _logNavigation('open_dialog', routeName ?? dialog.runtimeType.toString());
    return showDialog<T>(
      context: context,
      builder: (_) => dialog,
      barrierDismissible: barrierDismissable,
      routeSettings: RouteSettings(name: routeName ?? dialog.runtimeType.toString()),
    );
  }

  /// Open a bottom sheet.
  Future<T?> openBottomsheet<T>({
    required Widget sheet,
    String? routeName,
    bool isScrollControlled = false,
    bool isDismissible = true,
    bool useRootNavigator = false,
    bool enableDrag = true,
    Color? backgroundColor,
    ShapeBorder? shape,
    BuildContext? context,
  }) {
    context ??= _navigationContext;

    _logNavigation('open_bottom_sheet', routeName ?? sheet.runtimeType.toString());
    return showModalBottomSheet<T>(
      context: context,
      builder: (_) => sheet,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      routeSettings: RouteSettings(name: routeName ?? sheet.runtimeType.toString()),
      backgroundColor: backgroundColor,
      shape: shape,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height - 2 * kToolbarHeight,
      ),
    );
  }

  // ===== UTILITY METHODS =====

  /// Check if the current route is a specific route.
  bool isCurrentRoute(ArrkRoute route) {
    final currentRoute = GoRouterState.of(_navigationContext);
    return currentRoute.name == route.name || currentRoute.uri.path == route.path;
  }

  /// Get the current route.
  ArrkRoute getCurrentRoute() {
    final currentRoute = GoRouterState.of(_navigationContext);
    return ArrkRoute(
      name: currentRoute.name ?? '',
      path: currentRoute.uri.path,
      queryParameters: currentRoute.uri.queryParameters,
    );
  }

  /// Get the current route path.
  String? getCurrentRoutePath() {
    final context = currentContext;
    final currentRoute = GoRouterState.of(context);
    return currentRoute.uri.path;
  }

  // ===== PRIVATE METHODS =====

  /// Log navigation events. Products wanting analytics on navigation attach
  /// a `Logger.root` listener or a `NavigatorObserver` — the library does
  /// not depend on any analytics service.
  void _logNavigation(String action, Object route) {
    Logger('ArrkNavigator').fine('$action → $route');
  }
}
