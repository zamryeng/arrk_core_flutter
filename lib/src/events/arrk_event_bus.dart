import 'package:event_bus/event_bus.dart' as pkg;
import 'package:flutter/foundation.dart';

import 'arrk_event.dart';
import 'event_publisher.dart';
import 'event_stream.dart';

/// Typed broadcast hub for cross-feature [ArrkEvent]s, wrapping the
/// `event_bus` package.
///
/// One instance per app, registered in DI as all three types:
///
/// ```dart
/// @module
/// abstract class EventsModule {
///   @singleton
///   ArrkEventBus get eventBus => ArrkEventBus();
///   @singleton
///   EventPublisher publisher(ArrkEventBus bus) => bus;
///   @singleton
///   EventStream events(ArrkEventBus bus) => bus;
/// }
/// ```
///
/// Code depends on one half, never on the bus itself:
///
/// - **Publishers** ([EventPublisher]): capabilities only, after the action
///   succeeds.
/// - **Subscriber** ([EventStream]): the product's one `ArrkReactions`
///   class, which maps each event to capability calls and never publishes.
///
/// Publish an event only when a different feature reacts. When the reaction
/// is part of the same objective, the capability calls the other capability
/// directly.
class ArrkEventBus implements EventPublisher, EventStream {
  ArrkEventBus() : _bus = pkg.EventBus();

  @visibleForTesting
  ArrkEventBus.withBus(this._bus);

  final pkg.EventBus _bus;

  @override
  Stream<ArrkEvent> get all => _bus.on<ArrkEvent>();

  @override
  Stream<T> on<T extends ArrkEvent>() => _bus.on<T>();

  @override
  void fire(ArrkEvent event) => _bus.fire(event);

  @visibleForTesting
  void destroy() => _bus.destroy();
}
