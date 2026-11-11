import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/failure.dart';

/// Base type for the typed exceptions the data layer throws internally.
///
/// Every [ArrkException] knows how to flatten itself to a display-safe
/// [Failure] via [toFailure]; repository guards do that flattening so
/// nothing above the data layer sees an exception. The exception's [code]
/// always reaches the failure: subclasses implement [buildFailure] and are
/// handed the code to pass on.
abstract class ArrkException implements Exception {
  const ArrkException({this.code});

  /// The server's error code, verbatim, when this exception came off the
  /// wire. Null for exceptions raised locally (the failure may then carry a
  /// client default, see [ArrkFailureCodes]).
  final String? code;

  /// Builds the failure for this exception. [code] is this exception's
  /// [code]; pass it to the failure you build.
  @protected
  Failure buildFailure(String? code);

  /// The failure the repo guard hands upward.
  Failure toFailure() => buildFailure(code);

  @override
  String toString() => '$runtimeType - ${toFailure()}';
}

extension ArrkExceptionExtension on TimeoutException {
  TimeoutFailure toFailure() => TimeoutFailure();
}

/// The server failed (5xx).
class ServerException extends ArrkException {
  const ServerException({this.errorMessage, super.code});

  final String? errorMessage;

  @override
  ServerFailure buildFailure(String? code) => ServerFailure(message: errorMessage, code: code);
}

/// The request was rejected as invalid (4xx other than auth), or a success
/// response carried an error body.
class InputException extends ArrkException {
  const InputException({required this.errorMessage, super.code});

  final String? errorMessage;

  @override
  InputFailure buildFailure(String? code) => InputFailure(message: errorMessage, code: code);
}

/// Authentication is missing, bad or expired (401/403).
class UnauthorisedException extends ArrkException {
  const UnauthorisedException({this.errorMessage = '', super.code});

  final String errorMessage;

  @override
  BadAuthFailure buildFailure(String? code) => BadAuthFailure(message: errorMessage, code: code);
}

/// No route to the server.
class NetworkException extends ArrkException {
  const NetworkException({super.code});

  @override
  NetworkFailure buildFailure(String? code) => NetworkFailure(code: code);
}

/// Anything that does not fit the other types.
class UnknownException extends ArrkException {
  const UnknownException({super.code});

  @override
  UnknownFailure buildFailure(String? code) => UnknownFailure(code: code);
}

/// A business-rule refusal the backend reported with a user-facing message.
class ControlledException extends ArrkException {
  const ControlledException({this.errorMessage = '', super.code});

  final String errorMessage;

  @override
  ControlledFailure buildFailure(String? code) =>
      ControlledFailure(message: errorMessage, code: code);
}
