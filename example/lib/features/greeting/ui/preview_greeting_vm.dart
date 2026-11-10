import 'package:arrk_core_flutter/viewmodel.dart';
import 'package:injectable/injectable.dart';

import '../domain/dtos/greeting_draft_dto.dart';
import '../domain/use_cases/send_greeting_use_case.dart';

/// Screen glue for the preview step. The inbound Dto enters via
/// `@factoryParam` from the route builder. It never navigates: [onSend]
/// returns whether the send worked and the view routes on it.
@injectable
class PreviewGreetingVm extends ArrkViewModel {
  PreviewGreetingVm(@factoryParam this.draft, this._sendGreeting, super.messageSink);

  final GreetingDraftDto draft;
  final SendGreetingUseCase _sendGreeting;

  /// True when the greeting was sent.
  Future<bool> onSend() async {
    setState(VmState.busy);
    final result = await _sendGreeting.send(draft);
    if (result.hasError) {
      handleErrorAndSetVmState(result.error!);
      return false;
    }
    setState(VmState.none);
    showSuccess('Greeting sent to ${draft.recipientName}.');
    return true;
  }
}
