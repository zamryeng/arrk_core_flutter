import 'package:arrk_core_flutter/network.dart';
import 'package:injectable/injectable.dart';

/// Plumbing: the headers every request carries. Holds technical state only.
///
/// The session repo writes into it when the session changes. It never reads
/// a repo: services sit below repos.
@singleton
class ExampleRequestHeaders implements RequestHeadersProvider {
  final Map<String, String> _headers = <String, String>{'Content-Type': 'application/json'};

  @override
  Map<String, String> get requestHeaders => Map<String, String>.unmodifiable(_headers);

  /// Sets header [name] to [value], or removes it when [value] is null.
  void set(String name, String? value) {
    if (value == null) {
      _headers.remove(name);
    } else {
      _headers[name] = value;
    }
  }
}
