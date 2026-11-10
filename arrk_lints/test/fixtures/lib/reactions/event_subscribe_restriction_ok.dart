import '../_stubs.dart';

// OK: the reactions class is the one place that subscribes.
class WiredReactions extends ArrkReactions<ArrkEvent> {
  WiredReactions(super.events, this._stream);

  final EventStream _stream;

  @override
  void start() {
    _stream.on<ArrkEvent>();
    _stream.all;
    events.all;
  }

  @override
  Future<void> react(ArrkEvent event) async {}
}
