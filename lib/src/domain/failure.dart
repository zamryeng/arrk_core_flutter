/// Base type for every error the data layer hands upward.
///
/// Repos convert typed exceptions to [Failure]s inside their guards; domain
/// and UI consume the failure, never the exception. [message] is always
/// display-safe.
abstract class Failure {
  final String message;

  Failure(this.message);

  /// The write-path gate for long-init services: usecases and VMs
  /// short-circuit with `Failure.serviceNotReady(serviceName: ...)` when a
  /// service's status is `failed`. Same construction as [ServiceNotReady] —
  /// this spelling exists because the architecture spec prescribes it at the
  /// action site.
  static ServiceNotReady serviceNotReady({
    required String serviceName,
    Object? status,
    Object? lastError,
    String? message,
  }) =>
      ServiceNotReady(serviceName: serviceName, status: status, lastError: lastError, message: message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Represents a failure caused by a long-init service that is not in
/// `ServiceStatus.ready`.
///
/// Surfaced by repos on write paths when the underlying service has failed
/// to initialize or is still warming up. The UI maps this to a retry-capable
/// affordance — never a generic error toast — wiring its retry to re-driving
/// the service's `reinitialize()`.
class ServiceNotReady extends Failure {
  ServiceNotReady({
    required this.serviceName,
    this.status,
    this.lastError,
    String? message,
  }) : super(message ?? '$serviceName is not ready. Please try again.');

  /// Display-friendly name of the affected service (e.g. "Payments engine").
  final String serviceName;

  /// The service's status when the failure was raised, if known. Kept as
  /// `Object?` so [Failure] does not import the service-layer enum.
  final Object? status;

  /// The original init error, when the service is in `failed` state.
  final Object? lastError;
}

/// Represents a failure that occurred on the server side of the application,
/// typically resulting in a status code of 500 or above being returned by an API.
class ServerFailure extends Failure {
  ServerFailure({String? message}) : super(message ?? 'An error occurred');
}

/// Represents a failure that occurred due to invalid input or a failed request
/// from the user.
class InputFailure extends Failure {
  InputFailure({required String? message}) : super(message ?? 'Something went wrong');
}

/// Represents a failure that occurred due to bad or expired authentication
/// credentials, or a lack of access to a resource.
class BadAuthFailure extends Failure {
  BadAuthFailure({required String? message}) : super(message ?? 'Please sign in again');
}

/// Represents a failure that occurred due to an issue with the user's network
/// connection.
class NetworkFailure implements Failure {
  @override
  String get message => 'Please check your internet connection';
}

/// Represents a failure that occurred due to a request timeout.
class TimeoutFailure extends Failure {
  TimeoutFailure({String? message}) : super(message ??= 'Request timed out. Please try again.');
}

/// Represents an unknown failure that occurred within the application.
class UnknownFailure implements Failure {
  @override
  String get message => 'Something went wrong. Please try again.';
}

/// Represents a failure that occurred due to a controlled error — an outcome
/// the product anticipated and words itself. Products declare their own
/// [ControlledFailure]s (or subclasses) for domain-specific refusals.
class ControlledFailure extends Failure {
  ControlledFailure({required String? message}) : super(message ?? 'Something went wrong');
}
