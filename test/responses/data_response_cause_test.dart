import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:arrk_core_flutter/data.dart';
import 'package:arrk_core_flutter/responses.dart';

/// Verifies that [DataResponse.cause] surfaces the original typed exception
/// to callers, removing the need for string-matching the failure message.
///
/// The guard is implemented in [ArrkRepository.runDataWithGuard] /
/// [runStatusWithGuard].
void main() {
  group('DataResponse.cause via runDataWithGuard', () {
    test('preserves the typed ArrkException when the closure throws one', () async {
      final repo = _TestRepository();
      final response = await repo.failWith(InputException(errorMessage: 'bad input'));

      expect(response.hasError, isTrue);
      expect(response.error, isA<InputFailure>());
      expect(response.cause, isA<InputException>());
    });

    test('preserves the typed ArrkException for distinct subtypes', () async {
      final repo = _TestRepository();
      final serverEx = ServerException(errorMessage: 'server boom');
      final response = await repo.failWith(serverEx);

      expect(response.cause, isA<ServerException>());
      // Ensures the type guard still discriminates between sibling types.
      expect(response.cause, isNot(isA<InputException>()));
    });

    test('preserves arbitrary thrown objects as the cause', () async {
      final repo = _TestRepository();
      final response = await repo.failWith(_SyntheticError('boom'));

      expect(response.cause, isA<_SyntheticError>());
      expect((response.cause as _SyntheticError).reason, 'boom');
    });

    test('cause is null when the closure returns a success', () async {
      final repo = _TestRepository();
      final response = await repo.succeedWith(42);

      expect(response.hasError, isFalse);
      expect(response.data, 42);
      expect(response.cause, isNull);
    });

    test('TimeoutException maps to TimeoutFailure with cause preserved', () async {
      final repo = _TestRepository();
      final response = await repo.failWith(TimeoutException('slow'));

      expect(response.hasError, isTrue);
      expect(response.error, isA<TimeoutFailure>());
      expect(response.cause, isA<TimeoutException>());
    });

    test('NetworkException maps to NetworkFailure with cause preserved', () async {
      final repo = _TestRepository();
      final response = await repo.failWith(NetworkException());

      expect(response.hasError, isTrue);
      expect(response.error, isA<NetworkFailure>());
      expect(response.cause, isA<NetworkException>());
    });

    test('UnauthorisedException maps to BadAuthFailure with cause preserved', () async {
      final repo = _TestRepository();
      final response = await repo.failWith(UnauthorisedException(errorMessage: 'expired'));

      expect(response.hasError, isTrue);
      expect(response.error, isA<BadAuthFailure>());
      expect(response.cause, isA<UnauthorisedException>());
    });

    test('ControlledException maps to ControlledFailure with cause preserved', () async {
      final repo = _TestRepository();
      final response = await repo.failWith(ControlledException(errorMessage: 'controlled'));

      expect(response.hasError, isTrue);
      expect(response.error, isA<ControlledFailure>());
      expect(response.cause, isA<ControlledException>());
    });
  });

  group('StatusResponse.cause via runStatusWithGuard', () {
    test('preserves the typed ArrkException on failure', () async {
      final repo = _TestRepository();
      final response = await repo.failStatusWith(ServerException(errorMessage: 'server'));

      expect(response.hasError, isTrue);
      expect(response.cause, isA<ServerException>());
    });

    test('cause is null on a successful status response', () async {
      final repo = _TestRepository();
      final response = await repo.succeedStatus();

      expect(response.isSuccessful, isTrue);
      expect(response.cause, isNull);
    });

    test('TimeoutException in status guard maps to TimeoutFailure', () async {
      final repo = _TestRepository();
      final response = await repo.failStatusWith(TimeoutException('timeout'));

      expect(response.hasError, isTrue);
      expect(response.error, isA<TimeoutFailure>());
      expect(response.cause, isA<TimeoutException>());
    });

    test('arbitrary error in status guard maps to UnknownFailure', () async {
      final repo = _TestRepository();
      final response = await repo.failStatusWith(_SyntheticError('unexpected'));

      expect(response.hasError, isTrue);
      expect(response.error, isA<UnknownFailure>());
      expect(response.cause, isA<_SyntheticError>());
    });
  });
}

class _TestRepository extends ArrkRepository {
  Future<DataResponse<int>> failWith(Object e) {
    return runDataWithGuard<int>(() async {
      throw e;
    });
  }

  Future<DataResponse<int>> succeedWith(int value) {
    return runDataWithGuard<int>(() async {
      return DataResponse(data: value);
    });
  }

  Future<StatusResponse> failStatusWith(Object e) {
    return runStatusWithGuard(() async {
      throw e;
    });
  }

  Future<StatusResponse> succeedStatus() {
    return runStatusWithGuard(() async {
      return StatusResponse.successful();
    });
  }
}

class _SyntheticError {
  final String reason;
  _SyntheticError(this.reason);
}
