import 'package:event_bus/event_bus.dart' as pkg;
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'arrk_event.dart';

/// Typed broadcast hub for cross-feature [ArrkEvent]s, wrapping the
/// `event_bus` package as a thin DI-registered facade.
///
/// **Publishers:** usecases (after a domain operation completes) and the
/// session manager (after a session-state mutation). Repos and VMs must
/// never call [fire] — enforced by the `event_bus_publisher_restriction`
/// and `no_event_bus_in_repo` lint rules.
///
/// **Subscribers:** VMs (subscribed on init, cancelled in `dispose`),
/// usecases when the operation that caused the event also owns the
/// downstream invalidation, and product-level reaction wiring registered at
/// app startup for the residual cross-cutting cases.
///
/// ## Invariant: handlers do not fire events
///
/// Subscriber handlers must NOT call [fire] (directly or transitively).
/// Re-publishing inside a handler creates untraceable signal loops. The
/// `no_event_fire_in_handler` lint rule enforces this statically.
@singleton
class ArrkEventBus {
  ArrkEventBus() : _bus = pkg.EventBus();

  @visibleForTesting
  ArrkEventBus.withBus(this._bus);

  final pkg.EventBus _bus;

  /// All events flowing through the bus, in fire order.
  Stream<ArrkEvent> get all => _bus.on<ArrkEvent>();

  /// Typed stream of one concrete event class.
  ///
  /// ```dart
  /// _sub = bus.on<OrderPlaced>().listen((e) { ... });
  /// ```
  Stream<T> on<T extends ArrkEvent>() => _bus.on<T>();

  /// Publishes [event] to all current subscribers.
  void fire(ArrkEvent event) => _bus.fire(event);

  @visibleForTesting
  void destroy() => _bus.destroy();
}
