import '../events/arrk_event.dart';
import '../events/arrk_event_bus.dart';

/// [ArrkEventBus] that records every fired event for synchronous assertions,
/// while still delivering to live subscribers like the real bus.
///
/// ```dart
/// final bus = FakeArrkEventBus();
/// // ... exercise code that publishes ...
/// expect(bus.fired, hasLength(1));
/// expect(bus.firedOfType<OrderPlaced>().single.orderId, 'abc');
/// ```
///
/// Subscriptions via [on] / [all] behave exactly as the real bus, so a VM
/// under test can subscribe to this fake and react to events you fire.
class FakeArrkEventBus extends ArrkEventBus {
  final List<ArrkEvent> _fired = <ArrkEvent>[];

  /// Every event fired through this bus, in order. Read-only — mutate the
  /// bus via [fire], not this list.
  List<ArrkEvent> get fired => List<ArrkEvent>.unmodifiable(_fired);

  @override
  void fire(ArrkEvent event) {
    _fired.add(event);
    super.fire(event);
  }

  /// The fired events that are instances of [T], in order.
  List<T> firedOfType<T extends ArrkEvent>() => _fired.whereType<T>().toList();

  /// Whether at least one event of type [T] was fired.
  bool didFire<T extends ArrkEvent>() => _fired.any((e) => e is T);

  /// Clears the recorded history without affecting subscriptions.
  void clearRecorded() => _fired.clear();
}
