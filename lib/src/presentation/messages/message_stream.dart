import '../../domain/messages/user_message.dart';

/// The read side of the app's message channel.
///
/// Only the app's one `ArrkMessageHandler` takes this (and DI registration).
/// The `message_stream_restriction` lint enforces it.
abstract interface class MessageStream {
  /// Every pushed message, in push order.
  Stream<UserMessage> get messages;
}
