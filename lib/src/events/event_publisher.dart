import 'arrk_event.dart';

/// The publish half of the event bus.
///
/// Only capabilities (`domain/use_cases/`) take this, and they publish only
/// after the action succeeded. Nothing else fires: not repos, services,
/// view models, or the reactions class. The
/// `event_bus_publisher_restriction` lint enforces it.
abstract interface class EventPublisher {
  /// Publishes [event] to the subscriber.
  void fire(ArrkEvent event);
}
