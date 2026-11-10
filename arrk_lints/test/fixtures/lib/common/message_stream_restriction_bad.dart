import '../_stubs.dart';

// Reading messages anywhere but the handler is banned.
class MessageLogger {
  // expect_lint: message_stream_restriction (ctor parameter type)
  MessageLogger(MessageStream stream, this._channel) : _stream = stream;

  // expect_lint: message_stream_restriction (field type)
  final MessageStream _stream;
  // expect_lint: message_stream_restriction (field type)
  final ArrkMessageChannel _channel;
}

// A top-level lookup is not DI registration either.
// expect_lint: message_stream_restriction
MessageStream? globalStream;
