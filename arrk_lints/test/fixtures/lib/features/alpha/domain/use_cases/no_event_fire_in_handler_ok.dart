import '../../../../_stubs.dart';

class WellBehavedUseCase {
  WellBehavedUseCase(this._bus);
  final ArrkEventBus _bus;

  // OK: firing outside a listen() handler (this is also the right place to
  // publish, per event_bus_publisher_restriction).
  void publish() {
    _bus.fire(Object());
  }

  // OK: the handler only consumes; it does not re-fire.
  void wire() {
    _bus.on<Object>().listen((event) {
      event.toString();
    });
  }
}
