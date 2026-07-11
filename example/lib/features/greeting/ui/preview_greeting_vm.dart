import 'package:arrk_core_flutter/viewmodel.dart';
import 'package:injectable/injectable.dart';

import '../domain/dtos/greeting_draft_dto.dart';
import '../domain/use_cases/send_greeting_use_case.dart';
import '.navigation/greeting_router.dart';

/// Screen glue for the preview step. The inbound Dto enters via
/// `@factoryParam` from the route builder.
@injectable
class PreviewGreetingVm extends ArrkViewModel {
  PreviewGreetingVm(@factoryParam this.draft, this._sendGreeting);

  final GreetingDraftDto draft;
  final SendGreetingUseCase _sendGreeting;

  Future<void> onSend() async {
    setState(VmState.busy);
    final result = await _sendGreeting.send(draft);
    if (result.hasError) {
      handleErrorAndSetVmState(result.error!);
      return;
    }
    setState(VmState.none);
    messageHandler.showSuccess('Greeting sent to ${draft.recipientName}.');
    GreetingRouter.backToCompose();
  }
}
