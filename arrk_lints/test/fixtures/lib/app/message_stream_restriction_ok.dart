import '../_stubs.dart';

// OK: lib/app/ is the composition root, where doctrine puts di.dart.
MessageStream wireStream(ArrkMessageChannel channel) => channel;
