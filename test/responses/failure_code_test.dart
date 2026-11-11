import 'dart:async';

import 'package:arrk_core_flutter/data.dart';
import 'package:arrk_core_flutter/responses.dart';
import 'package:arrk_core_flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo extends ArrkRepository {
  Future<DataResponse<int>> failWith(Object error) => runDataWithGuard(() => throw error);
  Future<StatusResponse> statusFailWith(Object error) => runStatusWithGuard(() => throw error);
}

void main() {
  group('exceptions carry the server code into the failure', () {
    final cases = <ArrkException, Type>{
      const ServerException(errorMessage: 'boom', code: 'S1'): ServerFailure,
      const InputException(errorMessage: 'bad', code: 'I1'): InputFailure,
      const UnauthorisedException(errorMessage: 'who', code: 'A1'): BadAuthFailure,
      const ControlledException(errorMessage: 'no', code: 'C1'): ControlledFailure,
      const NetworkException(code: 'N1'): NetworkFailure,
      const UnknownException(code: 'U1'): UnknownFailure,
      const ServiceNotInitializedException('Db', code: 'D1'): ServiceNotReady,
      const ServiceInitException('Db', code: 'D2'): ServiceNotReady,
    };
    for (final entry in cases.entries) {
      test('${entry.key.runtimeType} -> ${entry.value}', () {
        final failure = entry.key.toFailure();
        expect(failure.runtimeType, entry.value);
        expect(failure.code, entry.key.code);
      });
    }
  });

  group('server-coded types have no code when the server sent none', () {
    test('Server, Input, BadAuth, Controlled', () {
      expect(const ServerException().toFailure().code, isNull);
      expect(const InputException(errorMessage: 'x').toFailure().code, isNull);
      expect(const UnauthorisedException().toFailure().code, isNull);
      expect(const ControlledException().toFailure().code, isNull);
    });
  });

  group('local failure types carry client defaults', () {
    test('defaults', () {
      expect(NetworkFailure().code, ArrkFailureCodes.network);
      expect(TimeoutFailure().code, ArrkFailureCodes.timeout);
      expect(UnknownFailure().code, ArrkFailureCodes.unknown);
      expect(ServiceNotReady(serviceName: 'Db').code, ArrkFailureCodes.serviceNotReady);
      expect(Failure.serviceNotReady(serviceName: 'Db').code, ArrkFailureCodes.serviceNotReady);
      expect(TimeoutException('t').toFailure().code, ArrkFailureCodes.timeout);
      expect(const NetworkException().toFailure().code, ArrkFailureCodes.network);
    });

    test('a server code wins over the default', () {
      expect(NetworkFailure(code: 'EDGE_DOWN').code, 'EDGE_DOWN');
      expect(const UnknownException(code: 'WEIRD').toFailure().code, 'WEIRD');
    });
  });

  test('toString shows the code when present', () {
    expect(ServerFailure(message: 'boom', code: 'S1').toString(), 'ServerFailure(S1): boom');
    expect(ServerFailure(message: 'boom').toString(), 'ServerFailure: boom');
    expect(const InputException(errorMessage: 'bad', code: 'I1').toString(),
        'InputException - InputFailure(I1): bad');
  });

  group('the repo guard keeps the code', () {
    test('DataResponse', () async {
      final r = await _Repo().failWith(const InputException(errorMessage: 'taken', code: 'IDENTITY_TAKEN'));
      expect(r.error, isA<InputFailure>());
      expect(r.error!.code, 'IDENTITY_TAKEN');
      expect(r.cause, isA<InputException>());
    });

    test('StatusResponse', () async {
      final r = await _Repo().statusFailWith(const ServerException(code: 'MAINTENANCE'));
      expect(r.error!.code, 'MAINTENANCE');
    });

    test('a timeout and an unclassified throw get the client defaults', () async {
      expect((await _Repo().failWith(TimeoutException('t'))).error!.code, ArrkFailureCodes.timeout);
      expect((await _Repo().failWith(StateError('x'))).error!.code, ArrkFailureCodes.unknown);
    });
  });
}
