/// Represents a named route with path and optional parameters.
///
/// Used throughout a product for type-safe routing with go_router. Route
/// definitions are product-owned — each feature declares its routes in its
/// `ui/.navigation/` router; the library carries zero product routes.
class ArrkRoute {
  final String name;
  final String path;
  final Map<String, String> queryParameters;
  final Map<String, String> pathParameters;

  const ArrkRoute({
    required this.name,
    required this.path,
    this.queryParameters = const {},
    this.pathParameters = const {},
  });

  @override
  String toString() => name;
}
