import 'dart:io' show File, SocketException;

export 'dart:io' show File;

/// Whether [error] is an io-platform socket failure. Web builds resolve the
/// stub variant, which always answers false — Dio reports web connectivity
/// failures as `DioExceptionType.connectionError` instead.
bool isSocketException(Object? error) => error is SocketException;

/// io platforms have real file access.
const bool platformSupportsFiles = true;

/// The file's path, for multipart uploads.
String filePath(File file) => file.path;
