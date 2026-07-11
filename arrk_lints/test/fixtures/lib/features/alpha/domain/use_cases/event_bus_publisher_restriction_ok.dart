import '../../../../_stubs.dart';

// OK: UseCases (domain/use_cases/) are allowed to publish events.
class DoSomethingUseCase {
  DoSomethingUseCase(this._bus);
  final ArrkEventBus _bus;

  void call() {
    _bus.fire(Object());
  }
}
