import '../../../../_stubs.dart';

// OK: capabilities (domain/use_cases/) publish, through the bus or the
// publisher half.
class DoSomethingUseCase {
  DoSomethingUseCase(this._bus, this._publisher);
  final ArrkEventBus _bus;
  final EventPublisher _publisher;

  void doIt() {
    _bus.fire(Object());
    _publisher.fire(Object());
  }
}
