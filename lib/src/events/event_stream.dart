import 'arrk_event.dart';

/// The subscribe half of the event bus.
///
/// Only the product's one `ArrkReactions` class takes this. View models,
/// views, repos and capabilities never subscribe. The
/// `event_subscribe_restriction` lint enforces it.
abstract interface class EventStream {
  /// Typed stream of one event class (or a sealed family base).
  Stream<T> on<T extends ArrkEvent>();

  /// Every event, in fire order.
  Stream<ArrkEvent> get all;
}
