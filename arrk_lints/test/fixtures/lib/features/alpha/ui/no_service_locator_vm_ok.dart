import '../../../_stubs.dart';

// OK: the sanctioned constructor-fallback injection pattern — the locator
// runs at construction time (constructor initializer), not in a method body.
class FallbackVm extends ArrkViewModel {
  FallbackVm([MessageSink? sink])
    : sink = sink ?? ServiceLocator.get<MessageSink>();
  final MessageSink sink;
}

// OK: a widget (non-VM) in ui/ constructing `model:` via the locator.
class AlphaScreen {
  Object build() => View(model: ServiceLocator.get<FallbackVm>());
}
