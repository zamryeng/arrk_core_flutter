import 'package:arrk_core_flutter/events.dart';
import 'package:injectable/injectable.dart';

import '../features/activity/domain/use_cases/record_activity_use_case.dart';
import '../features/greeting/domain/greeting_events.dart';

/// The app's one event subscriber: maps each event to capability calls.
/// Started in `main()` after DI. Never publishes.
@singleton
class AppReactions extends ArrkReactions<GreetingEvent> {
  AppReactions(super.events, this._recordActivity);

  final RecordActivityUseCase _recordActivity;

  @override
  Future<void> react(GreetingEvent event) async {
    switch (event) {
      case GreetingSent(:final recipientName):
        await _recordActivity.greetingSent(recipientName);
    }
  }
}
