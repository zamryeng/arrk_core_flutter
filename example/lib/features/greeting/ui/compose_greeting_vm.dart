import 'package:arrk_core_flutter/viewmodel.dart';
import 'package:injectable/injectable.dart';

import '../domain/models/greeting_tone.dart';
import '../domain/use_cases/send_greeting_use_case.dart';
import '.navigation/greeting_router.dart';

/// Screen glue for the compose step: holds form values, forwards to the
/// usecase, routes on success. No business decisions — validation and
/// preview derivation live in [SendGreetingUseCase].
@injectable
class ComposeGreetingVm extends ArrkViewModel {
  ComposeGreetingVm(this._sendGreeting);

  final SendGreetingUseCase _sendGreeting;

  String recipientName = '';
  GreetingTone tone = GreetingTone.friendly;

  void onNameChanged(String value) => recipientName = value;

  void onToneChanged(GreetingTone value) {
    tone = value;
    setState();
  }

  Future<void> onPreview() async {
    setState(VmState.busy);
    final result = await _sendGreeting.prepareDraft(recipientName: recipientName, tone: tone);
    if (result.hasError) {
      handleErrorAndSetVmState(result.error!);
      return;
    }
    setState(VmState.none);
    GreetingRouter.preview(result.data!);
  }
}
