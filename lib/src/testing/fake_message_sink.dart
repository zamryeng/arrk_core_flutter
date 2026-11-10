import '../domain/messages/message_sink.dart';
import '../domain/messages/user_message.dart';
import '../domain/messages/user_message_kind.dart';

/// [MessageSink] that records every push, for VM tests.
///
/// ```dart
/// final sink = FakeMessageSink();
/// final vm = ComposeGreetingVm(fakeSendGreeting, sink);
/// // ...
/// expect(sink.pushedOfKind(UserMessageKind.error), hasLength(1));
/// ```
class FakeMessageSink implements MessageSink {
  final List<UserMessage> _pushed = <UserMessage>[];

  /// Every pushed message, in order. Read-only.
  List<UserMessage> get pushed => List<UserMessage>.unmodifiable(_pushed);

  @override
  void push(UserMessage message) => _pushed.add(message);

  /// The pushed messages of [kind], in order.
  List<UserMessage> pushedOfKind(UserMessageKind kind) => _pushed.where((m) => m.kind == kind).toList();

  /// Clears the recorded history.
  void clearRecorded() => _pushed.clear();
}
