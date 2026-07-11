import 'package:arrk_core_flutter/view.dart';
import 'package:flutter/material.dart';

import 'preview_greeting_vm.dart';

/// Screen 2: preview and send. The VM (carrying the flow Dto) is constructed
/// by the route builder and handed in.
class PreviewGreetingView extends StatelessWidget {
  const PreviewGreetingView({super.key, required this.vm});

  final PreviewGreetingVm vm;

  @override
  Widget build(BuildContext context) {
    return ArrkView<PreviewGreetingVm>(
      model: vm,
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
                onPressed: vm.isBusy ? null : vm.onSend,
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
