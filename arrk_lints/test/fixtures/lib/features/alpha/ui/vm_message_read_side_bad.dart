import '../../../_stubs.dart';

// A VM only holds MessageSink: never the read side or the handler.
class EavesdroppingVm extends ArrkViewModel {
  EavesdroppingVm(
    // expect_lint: vm_uses_capabilities_only (ctor parameter: handler)
    ArrkMessageHandler handler,
    this._channel,
  ) : _handler = handler;

  // expect_lint: vm_uses_capabilities_only (field: channel)
  // expect_lint: message_stream_restriction (field type: channel)
  final ArrkMessageChannel _channel;
  // expect_lint: vm_uses_capabilities_only (field: handler)
  final ArrkMessageHandler _handler;
}
