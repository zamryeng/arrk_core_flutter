import 'user_message.dart';

/// The write side of the app's message channel.
///
/// Every `ArrkViewModel` takes one. Many classes write; one
/// `ArrkMessageHandler` reads and draws. A view model never calls UI code.
abstract interface class MessageSink {
  /// Queues [message] for the handler. Never throws.
  void push(UserMessage message);
}
