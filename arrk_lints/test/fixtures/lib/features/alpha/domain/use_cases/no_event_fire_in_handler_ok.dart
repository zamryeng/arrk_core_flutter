import '../../../../_stubs.dart';

// OK: a capability publishes outside any handler.
class WellBehavedUseCase {
  WellBehavedUseCase(this._publisher);
  final EventPublisher _publisher;

  void publish() {
    _publisher.fire(Object());
  }
}
