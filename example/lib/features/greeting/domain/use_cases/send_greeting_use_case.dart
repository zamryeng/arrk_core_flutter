import 'package:arrk_core_flutter/events.dart';
import 'package:arrk_core_flutter/responses.dart';
import 'package:injectable/injectable.dart';

import '../../data/greetings_repo.dart';
import '../dtos/greeting_draft_dto.dart';
import '../greeting_events.dart';
import '../models/greeting_tone.dart';

/// The user goal: send a greeting. One class, stateless methods for each
/// step of the goal — no execute()/call() convention.
///
/// Consumes `DataResponse`/`StatusResponse` from the repo; no try/catch in
/// domain. Fires `GreetingSent` — usecases and the session manager are the
/// only sanctioned event publishers.
@injectable
class SendGreetingUseCase {
  SendGreetingUseCase(this._greetingsRepo, this._eventBus);

  final GreetingsRepo _greetingsRepo;
  final ArrkEventBus _eventBus;

  /// Validates the input and derives the preview — the business half of the
  /// compose screen. Returns the Dto the flow carries forward.
  Future<DataResponse<GreetingDraftDto>> prepareDraft({
    required String recipientName,
    required GreetingTone tone,
  }) async {
    final name = recipientName.trim();
    if (name.isEmpty) {
      return DataResponse(error: InputFailure(message: 'Enter a recipient name first.'));
    }

    final template = await _greetingsRepo.fetchGreetingTemplate(tone);
    if (template.hasError) {
      return DataResponse(error: template.error, cause: template.cause);
    }

    return DataResponse(
      data: GreetingDraftDto(
        recipientName: name,
        tone: tone,
        previewText: template.data!.replaceAll('{name}', name),
      ),
    );
  }

  /// Sends a complete draft and records the fact on the event bus.
  Future<StatusResponse> send(GreetingDraftDto draft) async {
    if (!draft.isComplete) {
      return StatusResponse.failed(InputFailure(message: 'The draft is incomplete.'));
    }

    final result = await _greetingsRepo.sendGreeting(
      recipient: draft.recipientName,
      message: draft.previewText,
    );
    if (result.isSuccessful) {
      _eventBus.fire(GreetingSent(recipientName: draft.recipientName, firedAt: DateTime.now()));
    }
    return result;
  }
}
