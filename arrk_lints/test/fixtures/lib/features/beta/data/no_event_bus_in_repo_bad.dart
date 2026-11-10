import '../../../_stubs.dart';

// The data layer must not reference the bus or either of its halves.
class BetaRepo {
  BetaRepo(this._bus, this._publisher, this._events);
  // expect_lint: no_event_bus_in_repo
  final ArrkEventBus _bus;
  // expect_lint: no_event_bus_in_repo
  final EventPublisher _publisher;
  // expect_lint: no_event_bus_in_repo
  final EventStream _events;
}
