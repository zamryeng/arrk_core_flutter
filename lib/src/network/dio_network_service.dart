import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';

import '../data/arrk_exceptions.dart';
import 'platform/platform.dart';
import 'request_headers_provider.dart';
import 'rest_network_service.dart';

/// Dio-backed [RestNetworkService].
///
/// Products register one instance per API host (named registrations for
/// secondary hosts), handing in the [RequestHeadersProvider] whose headers
/// go on every call. The [DataErrorInterceptor] maps Dio failures to
/// the typed `ArrkException`s before they reach the data layer, carrying the
/// server's error code ([errorCodeOf]) so it reaches `Failure.code`.
class DioNetworkService extends RestNetworkService {
  final Dio _dio;
  final RequestHeadersProvider headersProvider;

  /// Reads the server's error code from a response body. Defaults to
  /// [defaultErrorCodeOf] (`body['code']`); pass your own when the API puts
  /// it elsewhere (e.g. `body['error']['code']`).
  final ErrorCodeReader errorCodeOf;

  DioNetworkService({
    required this.headersProvider,
    required super.baseUrl,
    required super.isProd,
    required super.sendTimeout,
    super.receiveTimeout,
    this.errorCodeOf = defaultErrorCodeOf,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: Uri.parse(baseUrl).toString(),
           connectTimeout: sendTimeout,
           sendTimeout: sendTimeout,
           receiveTimeout: receiveTimeout ?? sendTimeout,
         ),
       ) {
    _dio.interceptors.addAll([
      if (!isProd || kDebugMode) NetworkLoggerInterceptor(),
      DataErrorInterceptor(errorCodeOf: errorCodeOf),
    ]);
  }

  @override
  Future<Json> sendFormDataRequest(FormDataRequest request) async {
    final files = request.files.map((key, file) {
      final path = filePath(file);
      final type = lookupMimeType(path);
      final contentType = type != null ? MediaType.parse(type) : null;
      return MapEntry(key, MultipartFile.fromFileSync(path, contentType: contentType));
    });
    final otherData = request.body;

    final data = FormData.fromMap({...files, ...otherData});

    try {
      final response = await _dio.request<dynamic>(
        request.endpoint,
        data: data,
        queryParameters: request.queryParams,
        options: Options(
          method: request.method,
          contentType: 'multipart/form-data',
          headers: {...headersProvider.requestHeaders},
        ),
      );
      final res = response.data;
      if (res is! Map) {
        return {'data': res};
      }
      return res as Json;
    } on DioException catch (e) {
      throw e.error!;
    }
  }

  @override
  Future<Json> sendJsonRequest(JsonRequest request) async {
    try {
      // Merge the provider's headers with custom headers from the request.
      final headers = {
        ...headersProvider.requestHeaders,
        if (request.headers != null) ...request.headers!,
      };
      final response = await _dio.request<dynamic>(
        request.endpoint,
        data: request.body,
        queryParameters: request.queryParams,
        options: Options(
          method: request.method,
          contentType: 'Application/json',
          responseType: ResponseType.json,
          headers: headers,
        ),
      );
      final res = response.data;
      if (res is! Map) {
        return {'data': res};
      }
      // Handle errors coming with success status code.
      if (res['error'] as bool? ?? false) {
        throw InputException(errorMessage: res['message']?.toString(), code: errorCodeOf(res));
      }

      return res as Json;
    } on DioException catch (e) {
      throw e.error!;
    }
  }

  @override
  Future<ApiEnvelope> sendEnvelope(JsonRequest request) async {
    try {
      final headers = {
        ...headersProvider.requestHeaders,
        if (request.headers != null) ...request.headers!,
      };
      final response = await _dio.request<dynamic>(
        request.endpoint,
        data: request.body,
        queryParameters: request.queryParams,
        options: Options(
          method: request.method,
          contentType: 'application/json',
          responseType: ResponseType.json,
          headers: headers,
          // Accept every status code so the server's { status, code, message }
          // envelope survives on 4xx/5xx instead of being collapsed by
          // DataErrorInterceptor. Callers map `code` to their typed errors.
          validateStatus: (_) => true,
        ),
      );
      final data = response.data;
      final body = data is Map ? data.cast<String, dynamic>() : <String, dynamic>{'data': data};
      return ApiEnvelope(statusCode: response.statusCode ?? 0, body: body);
    } on DioException catch (e) {
      // Transport-level failures (timeout, no connectivity) are mapped to the
      // shared typed exceptions by DataErrorInterceptor before we get here.
      throw e.error!;
    }
  }
}

/// Reads a server error code out of a response body, or returns null.
typedef ErrorCodeReader = String? Function(Map<dynamic, dynamic> body);

/// The default [ErrorCodeReader]: `body['code']`, as a string.
String? defaultErrorCodeOf(Map<dynamic, dynamic> body) => body['code']?.toString();

/// Maps Dio failures to the typed `ArrkException`s and normalizes non-map
/// response bodies to `{ 'data': <payload> }`.
///
/// Every exception it raises from a response carries the body's `message`
/// and the server's error code (via [errorCodeOf]). A body that is not a JSON
/// object (an HTML error page, an empty body) yields no message and no code.
class DataErrorInterceptor extends Interceptor {
  DataErrorInterceptor({this.errorCodeOf = defaultErrorCodeOf});

  final ErrorCodeReader errorCodeOf;

  static final Logger _logger = Logger('DioNetworkService');

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (response.data is! Map) {
      response.data = {'data': response.data};
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.severe('Network error for ${err.requestOptions.uri}', err.error, err.stackTrace);
    if (err.isNetworkError) {
      handler.next(DioException(requestOptions: err.requestOptions, error: NetworkException()));
    } else if (err.isTimeoutError) {
      handler.next(
        DioException(
          requestOptions: err.requestOptions,
          error: TimeoutException('Request Timed out. Try again'),
        ),
      );
    } else {
      final body = _bodyOf(err.response);
      final message = body['message']?.toString();
      final code = errorCodeOf(body);
      final ArrkException error;
      if (err.isServerError) {
        error = ServerException(errorMessage: message, code: code);
      } else if (err.isUnauthorised) {
        error = UnauthorisedException(errorMessage: message ?? '', code: code);
      } else {
        error = InputException(errorMessage: message, code: code);
      }
      handler.next(DioException(requestOptions: err.requestOptions, error: error));
    }
  }

  /// The error response's body as a map: the decoded JSON object, or `{}`
  /// when there is no response or the body is not a JSON object.
  static Map<dynamic, dynamic> _bodyOf(Response<dynamic>? response) {
    final data = response?.data;
    if (data is Map) return data;
    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return decoded;
      } on FormatException {
        // Not JSON (an HTML error page): no message, no code.
      }
    }
    return const {};
  }
}

/// Debug-build request/response logger. Uses Dio's own [LogInterceptor];
/// products wanting fancier output replace it with their own interceptor.
class NetworkLoggerInterceptor extends LogInterceptor {
  NetworkLoggerInterceptor()
    : super(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
      );
}

extension DioExceptionExtension on DioException {
  bool get isTimeoutError => [
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionTimeout,
  ].contains(type);

  bool get isNetworkError =>
      isSocketException(error) || type == DioExceptionType.connectionError;

  bool get isServerError => (response?.statusCode ?? 501) >= 500;

  bool get isUnauthorised => [401, 403].contains(response?.statusCode);
}
