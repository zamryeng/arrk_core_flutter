/// Base type for every error the data layer hands upward.
///
/// Repos convert typed exceptions to [Failure]s inside their guards; domain
/// and UI consume the failure, never the exception. [message] is always
/// display-safe.
abstract class Failure {
  Failure(this.message, {this.code});

  /// Display-safe text for the user.
  final String message;

  /// Which error this is, as a stable string to branch on.
  ///
  /// When the failure came off the wire, this is the server's error code,
  /// verbatim (`ACCOUNT_LOCKED`, `IDENTITY_TAKEN`). Failure types that no
  /// response produced carry a documented client default instead — see
  /// [ArrkFailureCodes] — and a server code, when one exists, always wins.
  ///
  /// This is what lets a caller tell errors apart without every feature
  /// minting a parallel hierarchy of failure classes for its API's catalogue.
  /// Compare against the codes the endpoint documents; treat an
  /// unrecognised code as the generic case and show [message]. Local
  /// conditions the server never reports (a missing screen lock, a device
  /// below the floor) are better as their own typed [Failure]s.
  final String? code;

  /// The write-path gate for long-init services: usecases and repos
  /// short-circuit with `Failure.serviceNotReady(serviceName: ...)` when a
  /// service's status is `failed`. Same construction as [ServiceNotReady] —
  /// this spelling exists because the architecture spec prescribes it at the
  /// action site.
  static ServiceNotReady serviceNotReady({
    required String serviceName,
    Object? status,
    Object? lastError,
    String? message,
    String? code,
  }) => ServiceNotReady(
    serviceName: serviceName,
    status: status,
    lastError: lastError,
    message: message,
    code: code,
  );

  @override
  String toString() => '$runtimeType${code == null ? '' : '($code)'}: $message';
}

/// The client-side default [Failure.code]s, for failures no server response
/// produced. Branch on these instead of the string literals.
abstract final class ArrkFailureCodes {
  /// [NetworkFailure]: no route to the server.
  static const network = 'NETWORK_ERROR';

  /// [TimeoutFailure]: the request or operation timed out.
  static const timeout = 'TIMEOUT';

  /// [ServiceNotReady]: a long-init service is not ready.
  static const serviceNotReady = 'SERVICE_NOT_READY';

  /// [UnknownFailure]: anything the guard could not classify.
  static const unknown = 'UNKNOWN';
}

/// Represents a failure caused by a long-init service that is not in
/// `ServiceStatus.ready`.
///
/// Surfaced by repos on write paths when the underlying service has failed
/// to initialize or is still warming up. The UI maps this to a retry-capable
/// affordance — never a generic error toast — wiring its retry to re-driving
/// the service's `reinitialize()` (through a usecase).
class ServiceNotReady extends Failure {
  ServiceNotReady({
    required this.serviceName,
    this.status,
    this.lastError,
    String? message,
    String? code,
  }) : super(
         message ?? '$serviceName is not ready. Please try again.',
         code: code ?? ArrkFailureCodes.serviceNotReady,
       );

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
  ServerFailure({String? message, super.code}) : super(message ?? 'An error occurred');
}

/// Represents a failure that occurred due to invalid input or a failed request
/// from the user.
class InputFailure extends Failure {
  InputFailure({required String? message, super.code}) : super(message ?? 'Something went wrong');
}

/// Represents a failure that occurred due to bad or expired authentication
/// credentials, or a lack of access to a resource.
class BadAuthFailure extends Failure {
  BadAuthFailure({required String? message, super.code}) : super(message ?? 'Please sign in again');
}

/// Represents a failure that occurred due to an issue with the user's network
/// connection.
class NetworkFailure extends Failure {
  NetworkFailure({String? code})
    : super('Please check your internet connection', code: code ?? ArrkFailureCodes.network);
}

/// Represents a failure that occurred due to a request timeout.
class TimeoutFailure extends Failure {
  TimeoutFailure({String? message, String? code})
    : super(message ?? 'Request timed out. Please try again.', code: code ?? ArrkFailureCodes.timeout);
}

/// Represents an unknown failure that occurred within the application.
class UnknownFailure extends Failure {
  UnknownFailure({String? code})
    : super('Something went wrong. Please try again.', code: code ?? ArrkFailureCodes.unknown);
}

/// Represents a failure that occurred due to a controlled error — an outcome
/// the product anticipated and words itself. Products declare their own
/// [ControlledFailure]s (or subclasses) for domain-specific refusals.
class ControlledFailure extends Failure {
  ControlledFailure({required String? message, super.code})
    : super(message ?? 'Something went wrong');
}
