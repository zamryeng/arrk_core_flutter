import 'dart:async';

import 'package:arrk_core_flutter/data.dart';
import 'package:arrk_core_flutter/responses.dart';
import 'package:injectable/injectable.dart';

/// Owns the activity log: in memory, one instance for the app.
@singleton
class ActivityRepo extends ArrkRepository {
  final List<String> _entries = <String>[];
  final StreamController<List<String>> _changes = StreamController<List<String>>.broadcast();

  /// The log, newest last, then every change.
  Stream<List<String>> get entries async* {
    yield List<String>.unmodifiable(_entries);
    yield* _changes.stream;
  }

  Future<StatusResponse> add(String entry) => runStatusWithGuard(() async {
    _entries.add(entry);
    _changes.add(List<String>.unmodifiable(_entries));
    return StatusResponse.successful();
  });
}
