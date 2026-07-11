import '../../../_stubs.dart';

// In a feature domain/ file (not use_cases/), firing the bus is banned.
class PublisherVm {
  PublisherVm(this._bus);
  final ArrkEventBus _bus;

  void act() {
    // expect_lint: event_bus_publisher_restriction
    _bus.fire(Object());
  }
}
