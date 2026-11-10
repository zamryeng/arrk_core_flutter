import '../_stubs.dart';

// OK: the handler subclass reads the stream.
class ToastHandler extends ArrkMessageHandler {
  ToastHandler(MessageStream stream) : super(stream);

  @override
  void show(Object message) {}
}

// OK: a @module class wires the channel, wherever it lives.
@module
abstract class MessagesModule {
  ArrkMessageChannel get channel => ArrkMessageChannel();
  MessageSink sink(ArrkMessageChannel channel) => channel;
  MessageStream stream(ArrkMessageChannel channel) => channel;
}

// OK: writers take MessageSink.
class Writer {
  Writer(this._sink);
  final MessageSink _sink;
}
