import 'package:arrk_core_flutter/data.dart';
import 'package:arrk_core_flutter/responses.dart';
import 'package:injectable/injectable.dart';

import '../domain/models/greeting_tone.dart';

/// One-shot repo: request → response, no live state, `@injectable` factory.
///
/// The "remote" here is an in-memory stand-in so the example runs without a
/// backend; a real repo would call a `RestNetworkService` source inside the
/// same guards.
@injectable
class GreetingsRepo extends ArrkRepository {
  static const _templates = {
    GreetingTone.friendly: 'Hey {name}! Great to see you.',
    GreetingTone.formal: 'Dear {name}, it is a pleasure to make your acquaintance.',
  };

  Future<DataResponse<String>> fetchGreetingTemplate(GreetingTone tone) {
    return runDataWithGuard(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300)); // simulated latency
      final template = _templates[tone];
      if (template == null) throw ServerException(errorMessage: 'No template for $tone');
      return DataResponse(data: template);
    });
  }

  Future<StatusResponse> sendGreeting({required String recipient, required String message}) {
    return runStatusWithGuard(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      // A controlled failure path so the error flow is demonstrable: send to
      // a recipient named "fail" and watch the typed failure surface.
      if (recipient.toLowerCase() == 'fail') {
        throw ControlledException(errorMessage: "Couldn't deliver to $recipient. Try another name.");
      }
      return StatusResponse.successful();
    });
  }
}
