import 'dart:async';

import 'package:arrk_core_flutter/data.dart';
import 'package:arrk_core_flutter/network.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures what the interceptor passes on instead of continuing a chain.
class _CapturingHandler extends ErrorInterceptorHandler {
  DioException? passed;

  @override
  void next(DioException err) => passed = err;
}

final _options = RequestOptions(path: '/x');

DioException _withResponse(int status, Object? body) => DioException(
  requestOptions: _options,
  type: DioExceptionType.badResponse,
  response: Response<dynamic>(requestOptions: _options, statusCode: status, data: body),
);

Object? _run(DioException err, {DataErrorInterceptor? interceptor}) {
  final handler = _CapturingHandler();
  (interceptor ?? DataErrorInterceptor()).onError(err, handler);
  return handler.passed!.error;
}

void main() {
  test('500 with a coded body -> ServerException carrying message and code', () {
    final error = _run(_withResponse(500, {'message': 'down', 'code': 'MAINTENANCE'}));
    expect(error, isA<ServerException>());
    final e = error! as ServerException;
    expect(e.errorMessage, 'down');
    expect(e.code, 'MAINTENANCE');
    expect(e.toFailure().code, 'MAINTENANCE');
  });

  test('401 -> UnauthorisedException with the code', () {
    final error = _run(_withResponse(401, {'message': 'expired', 'code': 'TOKEN_EXPIRED'}));
    expect(error, isA<UnauthorisedException>());
    expect((error! as UnauthorisedException).code, 'TOKEN_EXPIRED');
  });

  test('422 -> InputException with the code', () {
    final error = _run(_withResponse(422, {'message': 'taken', 'code': 'IDENTITY_TAKEN'}));
    expect(error, isA<InputException>());
    expect((error! as InputException).code, 'IDENTITY_TAKEN');
  });

  test('a numeric code is read as a string', () {
    final error = _run(_withResponse(400, {'message': 'bad', 'code': 4001}));
    expect((error! as InputException).code, '4001');
  });

  test('a JSON string body is decoded', () {
    final error = _run(_withResponse(400, '{"message":"bad","code":"BAD_AMOUNT"}'));
    expect((error! as InputException).errorMessage, 'bad');
    expect((error as InputException).code, 'BAD_AMOUNT');
  });

  test('a non-JSON body (HTML error page) yields no message or code, and does not throw', () {
    final error = _run(_withResponse(404, '<html>Not Found</html>'));
    expect(error, isA<InputException>());
    expect((error! as InputException).errorMessage, isNull);
    expect((error as InputException).code, isNull);
  });

  test('a JSON array body yields no message or code', () {
    final error = _run(_withResponse(400, '[1,2]'));
    expect((error! as InputException).code, isNull);
  });

  test('a custom ErrorCodeReader reads a nested code', () {
    final interceptor = DataErrorInterceptor(
      errorCodeOf: (body) => (body['error'] as Map?)?['code']?.toString(),
    );
    final error = _run(
      _withResponse(400, {'message': 'bad', 'error': {'code': 'NESTED'}}),
      interceptor: interceptor,
    );
    expect((error! as InputException).code, 'NESTED');
  });

  test('a connection error -> NetworkException, whose failure has the default code', () {
    final error = _run(DioException(requestOptions: _options, type: DioExceptionType.connectionError));
    expect(error, isA<NetworkException>());
    expect((error! as NetworkException).toFailure().code, 'NETWORK_ERROR');
  });

  test('a timeout -> TimeoutException', () {
    final error = _run(DioException(requestOptions: _options, type: DioExceptionType.receiveTimeout));
    expect(error, isA<TimeoutException>());
  });
}
