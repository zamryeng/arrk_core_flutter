import 'package:arrk_core_flutter/responses.dart';
import 'package:injectable/injectable.dart';

import '../../data/activity_repo.dart';

/// Capability: keep the activity log. A different feature from greeting,
/// so it learns about sends from the `GreetingSent` event, through the
/// app's reactions class.
@injectable
class RecordActivityUseCase {
  RecordActivityUseCase(this._activityRepo);

  final ActivityRepo _activityRepo;

  Future<StatusResponse> greetingSent(String recipientName) =>
      _activityRepo.add('Greeted $recipientName');
}
