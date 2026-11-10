import '../domain/use_cases/load_alpha_use_case.dart';
import '../../../_stubs.dart';

// OK: the VM takes a capability and the message sink only.
class CapableVm extends ArrkViewModel {
  CapableVm(this._load, MessageSink sink) : _sink = sink;

  final LoadAlphaUseCase _load;
  final MessageSink _sink;
}
