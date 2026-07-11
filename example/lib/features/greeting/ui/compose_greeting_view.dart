import 'package:arrk_core_flutter/locator.dart';
import 'package:arrk_core_flutter/view.dart';
import 'package:flutter/material.dart';

import '../domain/models/greeting_tone.dart';
import 'compose_greeting_vm.dart';

/// Screen 1: compose a greeting. Renders form state, delegates every
/// decision to the VM.
class ComposeGreetingView extends StatelessWidget {
  const ComposeGreetingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ArrkView<ComposeGreetingVm>(
      model: ServiceLocator.get(),
      builder: (vm, context) => Scaffold(
        appBar: AppBar(title: const Text('Compose greeting')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Recipient name',
                  helperText: 'Send to "fail" to see the error path',
                  border: OutlineInputBorder(),
                ),
                onChanged: vm.onNameChanged,
              ),
              const SizedBox(height: 16),
              SegmentedButton<GreetingTone>(
                segments: const [
                  ButtonSegment(value: GreetingTone.friendly, label: Text('Friendly')),
                  ButtonSegment(value: GreetingTone.formal, label: Text('Formal')),
                ],
                selected: {vm.tone},
                onSelectionChanged: (selection) => vm.onToneChanged(selection.single),
              ),
              const Spacer(),
              FilledButton(
                onPressed: vm.isBusy ? null : vm.onPreview,
                child: vm.isBusy
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator())
                    : const Text('Preview'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
