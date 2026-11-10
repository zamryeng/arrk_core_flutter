import '../../_stubs.dart';

// The session is state, not events: a session service no longer gets an
// exemption to publish.
class SessionService {
  SessionService(this._publisher);
  final EventPublisher _publisher;

  void updateLocale(String locale) {
    // expect_lint: event_bus_publisher_restriction
    _publisher.fire(Object());
  }
}
