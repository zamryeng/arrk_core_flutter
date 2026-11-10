import 'package:flutter/material.dart';

import 'form_data_request.dart';
import 'json_request.dart';

export 'form_data_request.dart';
export 'json_request.dart';

/// Type alias for JSON data representation.
///
/// A convenient alias for `Map<String, dynamic>` used throughout the network
/// service for JSON request and response data.
typedef Json = Map<String, dynamic>;

/// Raw HTTP envelope returned by [RestNetworkService.sendEnvelope].
///
/// Unlike [RestNetworkService.sendJsonRequest], this preserves the server's
/// `{ status, code, message }` error envelope on non-2xx responses instead of
/// collapsing it into a typed exception. Callers that need the server's
/// `code` map it to their own typed errors themselves.
class ApiEnvelope {
  /// The HTTP status code of the response (0 if it could not be read).
  final int statusCode;

  /// The decoded response body. Always a map — non-map payloads are wrapped
  /// as `{ 'data': <payload> }` by the implementation.
  final Json body;

  const ApiEnvelope({required this.statusCode, required this.body});

  /// Whether the response is a 200 OK.
  bool get isOk => statusCode == 200;
}

/// Base class for REST API network services.
///
/// One interface for JSON and multipart requests with timeout handling and
/// environment-aware configuration. Implementations own the HTTP library,
/// authentication headers, and error conversion to the typed
/// `ArrkException`s; data sources consume this type and stay
/// transport-agnostic.
///
/// ```dart
/// final networkService = DioNetworkService(
///   headersProvider: requestHeaders,
///   baseUrl: 'https://api.example.com',
///   isProd: true,
///   sendTimeout: Duration(seconds: 30),
/// );
///
/// final response = await networkService.sendJsonRequest(
///   JsonRequest.get('/users')
/// );
/// ```
abstract class RestNetworkService {
  /// The base URL prepended to all endpoint paths: protocol + domain,
  /// optionally with a path prefix for API versioning.
  @protected
  final String baseUrl;

  /// Whether the service runs in production mode. Implementations use this
  /// to gate debug logging and development-only behavior.
  @protected
  final bool isProd;

  /// Timeouts: [sendTimeout] for request data, [receiveTimeout] for response
  /// data (defaults to [sendTimeout]).
  @protected
  final Duration sendTimeout, receiveTimeout;

  RestNetworkService({
    required this.baseUrl,
    required this.isProd,
    required this.sendTimeout,
    Duration? receiveTimeout,
  }) : receiveTimeout = receiveTimeout ?? sendTimeout;

  /// Sends a JSON HTTP request.
  ///
  /// Returns the decoded [Json] body. Throws the typed exceptions on
  /// failure: `NetworkException` (connectivity), `TimeoutException`,
  /// `ServerException` (5xx), `UnauthorisedException` (401/403),
  /// `InputException` (other 4xx / validation).
  Future<Json> sendJsonRequest(JsonRequest request);

  /// Sends a multipart/form-data request (file uploads plus form fields).
  ///
  /// Same return and error behavior as [sendJsonRequest]. io platforms only.
  Future<Json> sendFormDataRequest(FormDataRequest request);

  /// Sends a JSON request and returns the raw [ApiEnvelope] (status code +
  /// body) WITHOUT throwing on non-2xx responses.
  ///
  /// Use this when the server returns a structured error envelope
  /// (`{ status, code, message }`) whose `code` must be preserved — the
  /// standard [sendJsonRequest] collapses 4xx/5xx into generic typed
  /// exceptions and discards the `code`.
  ///
  /// Transport failures (timeout, no connectivity) still throw the shared
  /// typed exceptions (`TimeoutException`, `NetworkException`); only HTTP
  /// status errors are returned as data.
  ///
  /// Implementations that don't talk HTTP (mocks, document-store-backed) are
  /// not required to support this and throw [UnimplementedError] by default.
  Future<ApiEnvelope> sendEnvelope(JsonRequest request) =>
      throw UnimplementedError('sendEnvelope is not supported by $runtimeType');
}
