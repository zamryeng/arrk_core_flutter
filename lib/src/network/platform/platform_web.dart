/// Web stand-in for `dart:io`'s [File], so the network types compile on web.
///
/// Multipart form-data uploads are an io-platform feature; constructing or
/// using this stub on web throws [UnsupportedError] at runtime. Web screens
/// simply don't offer file-upload paths through `FormDataRequest`.
class File {
  File(this.path);

  final String path;
}

/// See the io variant. On web there is no [SocketException]; connectivity
/// failures surface as `DioExceptionType.connectionError`.
bool isSocketException(Object? error) => false;

/// Web has no file-system access for multipart uploads.
const bool platformSupportsFiles = false;

/// The file's path, for multipart uploads.
String filePath(File file) => file.path;
