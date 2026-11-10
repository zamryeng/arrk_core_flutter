import '../_stubs.dart';

class RecordUseCase {
  Future<void> record(Object event) async {}
}

// OK: the reactions class only maps events to capability calls.
class AppReactions extends ArrkReactions<ArrkEvent> {
  AppReactions(super.events, this._record);
  final RecordUseCase _record;

  @override
  Future<void> react(ArrkEvent event) => _record.record(event);
}
