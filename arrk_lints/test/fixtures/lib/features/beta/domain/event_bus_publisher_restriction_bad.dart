import '../../../_stubs.dart';

// In a feature domain/ file (not use_cases/), firing is banned on the bus
// and on the publisher half alike.
class PublisherVm {
  PublisherVm(this._bus, this._publisher);
  final ArrkEventBus _bus;
  final EventPublisher _publisher;

  void act() {
    // expect_lint: event_bus_publisher_restriction
    _bus.fire(Object());
    // expect_lint: event_bus_publisher_restriction
    _publisher.fire(Object());
  }
}
