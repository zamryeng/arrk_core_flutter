import '../../../../_stubs.dart';

// OK: injected final fields and static consts only.
class StatelessUseCase {
  StatelessUseCase(this._repo, EventPublisher publisher) : _publisher = publisher;

  static const pageSize = 20;

  final ArrkRepository _repo;
  final EventPublisher _publisher;

  int double(int x) {
    var local = x * 2; // locals are fine
    return local;
  }
}
