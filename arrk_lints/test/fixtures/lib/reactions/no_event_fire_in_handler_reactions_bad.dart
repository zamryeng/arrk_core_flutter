import '../_stubs.dart';

// The reactions class must not hold anything that can publish.
class LoopingReactions extends ArrkReactions<ArrkEvent> {
  // expect_lint: no_event_fire_in_handler (ctor parameter type)
  LoopingReactions(super.events, EventPublisher publisher) : _publisher = publisher;

  // expect_lint: no_event_fire_in_handler (field type)
  final EventPublisher _publisher;

  @override
  Future<void> react(ArrkEvent event) async {
    // expect_lint: no_event_fire_in_handler (lookup by type)
    ServiceLocator.get<ArrkEventBus>();
  }
}
