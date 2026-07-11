import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';

import '../data/arrk_exceptions.dart';
import '../session/arrk_session_manager.dart';
import 'platform/platform.dart';
import 'rest_network_service.dart';

/// Dio-backed [RestNetworkService].
///
/// Products register one instance per API host (named registrations for
/// secondary hosts), handing in the session manager whose [requestHeaders]
/// authenticate every call. The [DataErrorInterceptor] maps Dio failures to
/// the typed `ArrkException`s before they reach the data layer.
class DioNetworkService extends RestNetworkService {
  final Dio _dio;
  final ArrkSessionManager sessionManager;

  DioNetworkService({
    required this.sessionManager,
    required super.baseUrl,
    required super.isProd,
    required super.sendTimeout,
    super.receiveTimeout,
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
      DataErrorInterceptor(),
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
          headers: {...sessionManager.requestHeaders},
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
      // Merge session headers with custom headers from the request.
      final headers = {
        ...sessionManager.requestHeaders,
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
        throw InputException(errorMessage: res['message'].toString());
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
        ...sessionManager.requestHeaders,
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

/// Maps Dio failures to the typed `ArrkException`s and normalizes non-map
/// response bodies to `{ 'data': <payload> }`.
class DataErrorInterceptor extends Interceptor {
  DataErrorInterceptor();

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
    } else if (err.isServerError || err.isUnauthorised) {
      String? message;
      final responseData = err.response?.data;
      if (responseData is Map) {
        message = responseData['message']?.toString();
      }
      handler.next(
        DioException(
          requestOptions: err.requestOptions,
          error: err.isServerError
              ? ServerException(errorMessage: message)
              : UnauthorisedException(errorMessage: message ?? ''),
        ),
      );
    } else {
      Map<dynamic, dynamic> json;
      final responseData = err.response?.data;
      if (err.response == null) {
        json = {};
      } else if (responseData is Map) {
        json = responseData;
      } else {
        json = jsonDecode(responseData.toString()) as Map<dynamic, dynamic>;
      }
      handler.next(
        DioException(
          requestOptions: err.requestOptions,
          error: InputException(errorMessage: json['message']?.toString()),
        ),
      );
    }
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
