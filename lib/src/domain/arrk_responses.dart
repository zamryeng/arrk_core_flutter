import 'failure.dart';

/// A read result: exactly one of [data] or [error], never neither.
///
/// Produced by repository read paths (typically via
/// `ArrkRepository.runDataWithGuard`). Domain and view models consume it —
/// no try/catch above the data layer.
class DataResponse<T> {
  T? data;
  Failure? error;

  /// The original [Exception] that produced [error], when available.
  ///
  /// Repository `runDataWithGuard` catches typed `ArrkException`s and
  /// flattens them to [Failure] for the VM. That flattening loses the
  /// exception type, which becomes painful when the caller wants to `switch`
  /// on a typed protocol error. Without this field, VMs end up
  /// string-matching the failure message text.
  ///
  /// When non-null, callers can `cause is XException` directly and skip
  /// the string match. Always optional — repositories without typed
  /// exceptions can leave it null.
  Object? cause;

  bool get hasError => error != null;
  bool get isSuccessful => data != null;

  DataResponse({this.data, this.error, this.cause})
    : assert((data != null) || (error != null), 'Must have one of data or error');
}

/// A write result: success, or a [Failure].
///
/// Produced by repository write paths (typically via
/// `ArrkRepository.runStatusWithGuard`).
class StatusResponse {
  Failure? error;

  /// See [DataResponse.cause].
  Object? cause;

  bool get hasError => error != null;
  bool get isSuccessful => error == null;

  StatusResponse.failed(this.error, {this.cause});

  StatusResponse.successful() : error = null;
}
