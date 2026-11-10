import '../_stubs.dart';

// OK: anything under lib/di/ may wire the channel.
MessageStream wireStream(ArrkMessageChannel channel) => channel;
