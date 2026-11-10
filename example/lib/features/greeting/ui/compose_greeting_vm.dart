import 'package:arrk_core_flutter/viewmodel.dart';
import 'package:injectable/injectable.dart';

import '../domain/dtos/greeting_draft_dto.dart';
import '../domain/models/greeting_tone.dart';
import '../domain/use_cases/send_greeting_use_case.dart';

/// Screen glue for the compose step: holds form values and forwards to the
/// capability. No business decisions — validation and preview derivation
/// live in [SendGreetingUseCase]. It never navigates: [onPreview] returns
/// the draft and the view routes on it.
@injectable
class ComposeGreetingVm extends ArrkViewModel {
  ComposeGreetingVm(this._sendGreeting, super.messageSink);

  final SendGreetingUseCase _sendGreeting;

  String recipientName = '';
  GreetingTone tone = GreetingTone.friendly;

  void onNameChanged(String value) => recipientName = value;

  void onToneChanged(GreetingTone value) {
    tone = value;
    setState();
  }

  /// The draft to preview, or null when it could not be prepared (the
  /// error is already shown).
  Future<GreetingDraftDto?> onPreview() async {
    setState(VmState.busy);
    final result = await _sendGreeting.prepareDraft(recipientName: recipientName, tone: tone);
    if (result.hasError) {
      handleErrorAndSetVmState(result.error!);
      return null;
    }
    setState(VmState.none);
    return result.data;
  }
}
