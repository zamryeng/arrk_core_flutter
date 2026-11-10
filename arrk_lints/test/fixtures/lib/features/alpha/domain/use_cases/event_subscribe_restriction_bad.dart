import '../../../../_stubs.dart';

// Capabilities do not subscribe either.
class SubscribingUseCase {
  SubscribingUseCase(this._bus);
  final ArrkEventBus _bus;

  void wire() {
    // expect_lint: event_subscribe_restriction
    _bus.on<Object>().listen((event) {});
  }
}
