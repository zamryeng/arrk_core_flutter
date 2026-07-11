// ignore_for_file: constant_identifier_names

/// HTTP GET method constant.
const GET = 'GET';

/// HTTP POST method constant.
const POST = 'POST';

/// HTTP PATCH method constant.
const PATCH = 'PATCH';

/// HTTP PUT method constant.
const PUT = 'PUT';

/// HTTP DELETE method constant.
const DELETE = 'DELETE';

/// A JSON HTTP request: endpoint, method, body, query parameters, and
/// authentication flag.
///
/// Use the named constructors per method; every request defaults to
/// authenticated ([useToken]) unless disabled.
///
/// ```dart
/// final getRequest = JsonRequest.get('/api/boards');
/// final postRequest = JsonRequest.post('/api/boards', {'name': 'Weekly'});
/// final publicRequest = JsonRequest.get('/api/health', useToken: false);
/// ```
class JsonRequest {
  /// The API endpoint path, relative to the service's base URL. Starts with
  /// a forward slash.
  final String endpoint;

  /// Whether to include the session's authentication headers. Set false for
  /// public endpoints.
  final bool useToken;

  /// The request body. Empty for GET; JSON-encoded by the network service
  /// otherwise.
  final Map<String, dynamic> body;

  /// Optional query-string parameters (filtering, pagination, sorting).
  final Map<String, String>? queryParams;

  /// The HTTP method — one of the [GET]/[POST]/[PATCH]/[PUT]/[DELETE]
  /// constants.
  final String method;

  /// Optional custom headers, merged over the network service's defaults.
  final Map<String, String>? headers;

  /// Creates a request with every field explicit. Prefer the per-method
  /// named constructors.
  JsonRequest(
    this.method, {
    required this.endpoint,
    required this.body,
    required this.queryParams,
    this.useToken = true,
    this.headers,
  });

  /// Creates a GET request (no body).
  JsonRequest.get(this.endpoint, {this.queryParams, this.useToken = true, this.headers})
    : body = const {},
      method = GET;

  /// Creates a POST request.
  JsonRequest.post(this.endpoint, this.body, {this.queryParams, this.useToken = true, this.headers})
    : method = POST;

  /// Creates a PATCH request.
  JsonRequest.patch(
    this.endpoint,
    this.body, {
    this.queryParams,
    this.useToken = true,
    this.headers,
  }) : method = PATCH;

  /// Creates a PUT request.
  JsonRequest.put(this.endpoint, this.body, {this.queryParams, this.useToken = true, this.headers})
    : method = PUT;

  /// Creates a DELETE request.
  JsonRequest.delete(
    this.endpoint,
    this.body, {
    this.queryParams,
    this.useToken = true,
    this.headers,
  }) : method = DELETE;

  /// Requests are equal when endpoint and method match — the identity used
  /// for caching and deduplication.
  @override
  bool operator ==(other) =>
      other is JsonRequest && endpoint == other.endpoint && method == other.method;

  @override
  int get hashCode => endpoint.hashCode;
}
