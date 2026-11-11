import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:arrk_core_flutter/data.dart';
import 'package:arrk_core_flutter/responses.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _ConcreteRepo extends ArrkRepository {
  Future<DataResponse<T>> runData<T>(Future<DataResponse<T>> Function() closure) =>
      runDataWithGuard<T>(closure);

  Future<StatusResponse> runStatus(Future<StatusResponse> Function() closure) =>
      runStatusWithGuard(closure);

  Failure exposedConvertException(dynamic e) => convertException(e);

  Map<String, String> exposedPaginationQuery(int page) =>
      generatePaginationQuery(page);

  void setResultsPerPage(int n) => resultsPerPage = n;
}

/// A product-defined exception: extends the base and builds its own failure.
class _CustomArrkException extends ArrkException {
  final String msg;
  const _CustomArrkException(this.msg);

  @override
  Failure buildFailure(String? code) => ControlledFailure(message: msg, code: code);

  @override
  String toString() => 'CustomArrkException($msg)';
}

class _ArbitraryError implements Exception {
  final String reason;
  const _ArbitraryError(this.reason);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _ConcreteRepo repo;

  setUp(() => repo = _ConcreteRepo());

  group('runDataWithGuard — success path', () {
    test('returns the closure response untouched on success', () async {
      final response = await repo.runData(() async => DataResponse<int>(data: 42));

      expect(response.isSuccessful, isTrue);
      expect(response.data, 42);
      expect(response.error, isNull);
      expect(response.cause, isNull);
    });

    test('wraps list result directly', () async {
      final response = await repo.runData<List<String>>(
        () async => DataResponse<List<String>>(data: ['a', 'b']),
      );

      expect(response.data, ['a', 'b']);
    });
  });

  group('runDataWithGuard — ArrkException paths', () {
    test('ServerException → ServerFailure, cause preserved', () async {
      final ex = ServerException(errorMessage: 'server down');
      final response = await repo.runData<int>(() async => throw ex);

      expect(response.hasError, isTrue);
      expect(response.error, isA<ServerFailure>());
      expect(response.cause, same(ex));
    });

    test('InputException → InputFailure, cause preserved', () async {
      final ex = InputException(errorMessage: 'bad input');
      final response = await repo.runData<int>(() async => throw ex);

      expect(response.hasError, isTrue);
      expect(response.error, isA<InputFailure>());
      expect(response.cause, same(ex));
    });

    test('NetworkException → NetworkFailure, cause preserved', () async {
      final ex = NetworkException();
      final response = await repo.runData<int>(() async => throw ex);

      expect(response.hasError, isTrue);
      expect(response.error, isA<NetworkFailure>());
      expect(response.cause, same(ex));
    });

    test('UnauthorisedException → BadAuthFailure, cause preserved', () async {
      final ex = UnauthorisedException(errorMessage: 'expired token');
      final response = await repo.runData<int>(() async => throw ex);

      expect(response.hasError, isTrue);
      expect(response.error, isA<BadAuthFailure>());
      expect(response.cause, same(ex));
    });

    test('ControlledException → ControlledFailure, cause preserved', () async {
      final ex = ControlledException(errorMessage: 'controlled');
      final response = await repo.runData<int>(() async => throw ex);

      expect(response.hasError, isTrue);
      expect(response.error, isA<ControlledFailure>());
      expect(response.cause, same(ex));
    });

    test('custom ArrkException → its toFailure result, cause preserved', () async {
      const ex = _CustomArrkException('custom message');
      final response = await repo.runData<int>(() async => throw ex);

      expect(response.hasError, isTrue);
      expect(response.error, isA<ControlledFailure>());
      expect(response.cause, same(ex));
    });
  });

  group('runDataWithGuard — non-ArrkException paths', () {
    test('TimeoutException → TimeoutFailure, cause preserved', () async {
      final ex = TimeoutException('timed out');
      final response = await repo.runData<int>(() async => throw ex);

      expect(response.hasError, isTrue);
      expect(response.error, isA<TimeoutFailure>());
      expect(response.cause, same(ex));
    });

    test('arbitrary Exception → UnknownFailure, cause preserved', () async {
      const ex = _ArbitraryError('unexpected');
      final response = await repo.runData<int>(() async => throw ex);

      expect(response.hasError, isTrue);
      expect(response.error, isA<UnknownFailure>());
      expect(response.cause, same(ex));
    });

    test('arbitrary Error → UnknownFailure, cause preserved', () async {
      final ex = StateError('state error');
      final response = await repo.runData<int>(() async => throw ex);

      expect(response.hasError, isTrue);
      expect(response.error, isA<UnknownFailure>());
      expect(response.cause, same(ex));
    });
  });

  group('runStatusWithGuard — success path', () {
    test('returns successful StatusResponse untouched', () async {
      final response = await repo.runStatus(() async => StatusResponse.successful());

      expect(response.isSuccessful, isTrue);
      expect(response.error, isNull);
      expect(response.cause, isNull);
    });
  });

  group('runStatusWithGuard — error paths', () {
    test('ServerException → ServerFailure, cause preserved', () async {
      final ex = ServerException(errorMessage: 'server');
      final response = await repo.runStatus(() async => throw ex);

      expect(response.hasError, isTrue);
      expect(response.error, isA<ServerFailure>());
      expect(response.cause, same(ex));
    });

    test('TimeoutException → TimeoutFailure, cause preserved', () async {
      final ex = TimeoutException('slow');
      final response = await repo.runStatus(() async => throw ex);

      expect(response.hasError, isTrue);
      expect(response.error, isA<TimeoutFailure>());
      expect(response.cause, same(ex));
    });

    test('arbitrary Exception → UnknownFailure, cause preserved', () async {
      const ex = _ArbitraryError('boom');
      final response = await repo.runStatus(() async => throw ex);

      expect(response.hasError, isTrue);
      expect(response.error, isA<UnknownFailure>());
      expect(response.cause, same(ex));
    });

    test('NetworkException → NetworkFailure, cause preserved', () async {
      final ex = NetworkException();
      final response = await repo.runStatus(() async => throw ex);

      expect(response.hasError, isTrue);
      expect(response.error, isA<NetworkFailure>());
      expect(response.cause, same(ex));
    });
  });

  group('generatePaginationQuery', () {
    test('page 1 with default resultsPerPage → skip 0, limit 15', () {
      final q = repo.exposedPaginationQuery(1);
      expect(q['skip'], '0');
      expect(q['limit'], '15');
    });

    test('page 2 with default resultsPerPage → skip 15, limit 15', () {
      final q = repo.exposedPaginationQuery(2);
      expect(q['skip'], '15');
      expect(q['limit'], '15');
    });

    test('page 3 with default resultsPerPage → skip 30, limit 15', () {
      final q = repo.exposedPaginationQuery(3);
      expect(q['skip'], '30');
      expect(q['limit'], '15');
    });

    test('page 1 with custom resultsPerPage → skip 0, correct limit', () {
      repo.setResultsPerPage(20);
      final q = repo.exposedPaginationQuery(1);
      expect(q['skip'], '0');
      expect(q['limit'], '20');
    });

    test('page 4 with custom resultsPerPage → correct skip', () {
      repo.setResultsPerPage(10);
      final q = repo.exposedPaginationQuery(4);
      expect(q['skip'], '30');
      expect(q['limit'], '10');
    });

    test('returns string values for skip and limit', () {
      final q = repo.exposedPaginationQuery(1);
      expect(q['skip'], isA<String>());
      expect(q['limit'], isA<String>());
    });
  });

  group('convertException', () {
    test('ArrkException → its toFailure result', () {
      final f = repo.exposedConvertException(ServerException(errorMessage: 'srv'));
      expect(f, isA<ServerFailure>());
    });

    test('TimeoutException → TimeoutFailure', () {
      final f = repo.exposedConvertException(TimeoutException('t'));
      expect(f, isA<TimeoutFailure>());
    });

    test('arbitrary object → UnknownFailure', () {
      final f = repo.exposedConvertException(StateError('x'));
      expect(f, isA<UnknownFailure>());
    });

    test('arbitrary Exception → UnknownFailure', () {
      final f = repo.exposedConvertException(Exception('generic'));
      expect(f, isA<UnknownFailure>());
    });
  });
}
