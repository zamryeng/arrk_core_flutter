import 'dart:async';

import '../domain/failure.dart';

/// Base type for the typed exceptions the data layer throws internally.
///
/// Every [ArrkException] knows how to flatten itself to a display-safe
/// [Failure] via [toFailure]; repository guards do that flattening so
/// nothing above the data layer sees an exception.
abstract class ArrkException implements Exception {
  const ArrkException();
  Failure toFailure();

  @override
  String toString() {
    return '$runtimeType - ${toFailure().message}';
  }
}

extension ArrkExceptionExtension on TimeoutException {
  TimeoutFailure toFailure() => TimeoutFailure();
}

class ServerException implements ArrkException {
  final String? errorMessage;
  ServerException({this.errorMessage});
  @override
  ServerFailure toFailure() => ServerFailure(message: errorMessage);
}

class InputException implements ArrkException {
  final String? errorMessage;
  InputException({required this.errorMessage});
  @override
  InputFailure toFailure() => InputFailure(message: errorMessage);
}

class UnauthorisedException implements ArrkException {
  final String errorMessage;
  UnauthorisedException({this.errorMessage = ''});
  @override
  BadAuthFailure toFailure() => BadAuthFailure(message: errorMessage);
}

class NetworkException implements ArrkException {
  @override
  Failure toFailure() => NetworkFailure();
}

class UnknownException implements ArrkException {
  @override
  Failure toFailure() => UnknownFailure();
}

class ControlledException implements ArrkException {
  final String errorMessage;
  ControlledException({this.errorMessage = ''});
  @override
  Failure toFailure() => ControlledFailure(message: errorMessage);
}
