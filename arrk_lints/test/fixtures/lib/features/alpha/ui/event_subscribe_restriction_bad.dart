import '../../../_stubs.dart';

class ListeningVm extends ArrkViewModel {
  ListeningVm(this._bus, this._events);

  final ArrkEventBus _bus;
  // expect_lint: event_subscribe_restriction (field typed EventStream)
  final EventStream _events;

  void wire() {
    // expect_lint: event_subscribe_restriction (on<> on the bus)
    _bus.on<Object>();
    // expect_lint: event_subscribe_restriction (on<> on the stream half)
    _events.on<Object>();
    // expect_lint: event_subscribe_restriction (all, prefixed)
    _events.all;
    // expect_lint: event_subscribe_restriction (all, property access)
    this._bus.all;
  }
}
