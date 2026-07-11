/// Platform seam for the network layer: `File` and socket-error detection.
///
/// io platforms get `dart:io`'s real types; web gets compile-safe stubs
/// (multipart file upload throws [UnsupportedError] at runtime there). This
/// keeps every barrel of the package importable in a web build.
library;

export 'platform_web.dart' if (dart.library.io) 'platform_io.dart';
