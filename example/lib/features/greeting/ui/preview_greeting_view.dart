import 'package:arrk_core_flutter/locator.dart';
import 'package:arrk_core_flutter/view.dart';
import 'package:flutter/material.dart';

import '.navigation/greeting_router.dart';
import '../domain/dtos/greeting_draft_dto.dart';
import 'preview_greeting_vm.dart';

/// Screen 2: preview and send. The route hands in the flow Dto; the view
/// builds its VM from it once (`create:`), so route rebuilds never mint a
/// second VM. Navigates back once the VM reports the send worked.
class PreviewGreetingView extends StatelessWidget {
  const PreviewGreetingView({super.key, required this.draft});

  final GreetingDraftDto draft;

  @override
  Widget build(BuildContext context) {
    return ArrkView<PreviewGreetingVm>(
      create: () => ServiceLocator.get<PreviewGreetingVm>(param1: draft),
      builder: (vm, context) => Scaffold(
        appBar: AppBar(title: const Text('Preview')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    vm.draft.previewText,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: vm.isBusy
                    ? null
                    : () async {
                        if (await vm.onSend()) GreetingRouter.backToCompose();
                      },
                child: vm.isBusy
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator())
                    : Text('Send to ${vm.draft.recipientName}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
