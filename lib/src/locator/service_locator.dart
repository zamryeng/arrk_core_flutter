import 'dart:async';

import 'package:get_it/get_it.dart';

/// GetIt facade and DI bootstrap seam.
///
/// A product's `main` hands its generated `@InjectableInit` function to
/// [configure]; call sites resolve via `ServiceLocator.get<T>()` exactly as
/// they would with a static config. Feature modules that register manually
/// extend this class and implement [register].
///
/// ```dart
/// // main.dart
/// await ServiceLocator.configure((getIt) => getIt.init());
/// ```
abstract class ServiceLocator {
  final GetIt locator;

  ServiceLocator(this.locator);

  FutureOr<void> register();

  static GetIt get get => GetIt.instance;

  static FutureOr<void> Function(GetIt locator)? _init;

  /// Bootstraps DI: stores [init] (so [reset] can re-run it) and runs it.
  /// The product passes its generated `@InjectableInit` entry point — a
  /// library cannot statically import generated config.
  static Future<void> configure(FutureOr<void> Function(GetIt locator) init) async {
    _init = init;
    await init(get);
  }

  /// Resets every registration, then re-runs the configured init.
  static Future<void> reset() async {
    await get.reset();
    final init = _init;
    if (init != null) await init(get);
  }

  /// Resets one lazy-singleton instance so its next resolution rebuilds it.
  static void resetInstance<T extends Object>() {
    get.resetLazySingleton<T>();
  }
}
