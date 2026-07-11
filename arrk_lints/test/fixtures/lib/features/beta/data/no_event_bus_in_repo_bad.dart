import '../../../_stubs.dart';

// expect_lint: no_event_bus_in_repo
// The data layer must not reference ArrkEventBus at all.
class BetaRepo {
  BetaRepo(this._bus);
  final ArrkEventBus _bus;
}
