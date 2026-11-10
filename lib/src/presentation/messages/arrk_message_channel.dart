import 'dart:async';

import '../../domain/messages/message_sink.dart';
import '../../domain/messages/user_message.dart';
import 'message_stream.dart';

/// The app's message channel: [MessageSink] for view models, [MessageStream]
/// for the one `ArrkMessageHandler`.
///
/// One instance per app, registered in DI as a singleton under both
/// interfaces:
///
/// ```dart
/// @module
/// abstract class MessagesModule {
///   @singleton
///   ArrkMessageChannel get messageChannel => ArrkMessageChannel();
///   @singleton
///   MessageSink messageSink(ArrkMessageChannel channel) => channel;
///   @singleton
///   MessageStream messageStream(ArrkMessageChannel channel) => channel;
/// }
/// ```
///
/// **A push with no listener is dropped.** Start the handler in `main()`
/// before anything can push.
class ArrkMessageChannel implements MessageSink, MessageStream {
  final StreamController<UserMessage> _controller = StreamController<UserMessage>.broadcast();

  @override
  Stream<UserMessage> get messages => _controller.stream;

  @override
  void push(UserMessage message) {
    if (_controller.isClosed || !_controller.hasListener) return;
    _controller.add(message);
  }

  /// Closes the channel. Later pushes are dropped.
  Future<void> close() => _controller.close();
}
