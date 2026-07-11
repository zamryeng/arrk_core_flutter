import '../../../../_stubs.dart';

class LoopingUseCase {
  LoopingUseCase(this._bus);
  final ArrkEventBus _bus;

  void wire() {
    _bus.on<Object>().listen((event) {
      // expect_lint: no_event_fire_in_handler
      _bus.fire(Object());
    });
  }
}
