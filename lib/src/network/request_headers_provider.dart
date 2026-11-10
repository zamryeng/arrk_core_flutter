/// The one source of outgoing-request headers.
///
/// Plumbing, not app state: a service that holds what the network needs to
/// authenticate and describe a call (tokens, device id, language tags).
/// `DioNetworkService` reads [requestHeaders] on every request and reads
/// nothing else.
///
/// The session repo writes into the product's implementation when the
/// session changes. The provider never reads a repo: services sit below
/// repos.
abstract interface class RequestHeadersProvider {
  /// The headers to send with every request. Read on each call, so changes
  /// apply to the next request.
  Map<String, String> get requestHeaders;
}
