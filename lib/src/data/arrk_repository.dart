import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../domain/arrk_responses.dart';
import '../domain/failure.dart';
import 'arrk_exceptions.dart';

/// Base class for repositories — the data layer's concrete carriers.
///
/// Provides the shared plumbing every repo needs: guarded execution that
/// converts typed exceptions to [Failure]s, logging, and pagination query
/// generation. Repos are CONCRETE classes (no interfaces — the
/// `no_repo_interfaces` lint enforces it) and never call other repos.
///
/// The guards are `@protected` and stay that way: they are data-layer-only.
/// Domain consumes [DataResponse]/[StatusResponse]; nothing above `data/`
/// may guard (`no_try_catch_in_domain` enforces the domain side).
///
/// ```dart
/// class ActivityRepo extends ArrkRepository {
///   Future<DataResponse<List<Activity>>> getActivities(int page) {
///     return runDataWithGuard(() async {
///       final json = await _api.sendJsonRequest(
///         JsonRequest.get('/activities', queryParams: generatePaginationQuery(page)),
///       );
///       return DataResponse(data: Activity.listFromJson(json));
///     });
///   }
/// }
/// ```
abstract class ArrkRepository {
  ArrkRepository();

  /// Page size used by [generatePaginationQuery]. Override per repo when a
  /// different size fits the data.
  @protected
  int resultsPerPage = 15;

  /// Logger named after the concrete repo type.
  @protected
  Logger get logger => Logger(runtimeType.toString());

  /// Pagination query parameters for [page] (1-based):
  /// `{'skip': (page - 1) * resultsPerPage, 'limit': resultsPerPage}`.
  @protected
  Map<String, String> generatePaginationQuery(int page) => {
    'skip': ((page - 1) * resultsPerPage).toString(),
    'limit': resultsPerPage.toString(),
  };

  /// Converts an exception to its [Failure]: [ArrkException]s via their own
  /// [ArrkException.toFailure], [TimeoutException] to [TimeoutFailure],
  /// anything else to [UnknownFailure].
  @protected
  Failure convertException(dynamic e) {
    if (e is ArrkException) {
      return e.toFailure();
    } else if (e is TimeoutException) {
      return TimeoutFailure();
    } else {
      return UnknownFailure();
    }
  }

  /// Runs a read operation under the guard: exceptions are logged (except
  /// [NetworkException]/[ControlledException] — expected outcomes, not
  /// defects) and converted to a failed [DataResponse]. The original typed
  /// exception is preserved via [DataResponse.cause] so callers can `switch`
  /// on it without string-matching the failure message.
  @protected
  Future<DataResponse<T>> runDataWithGuard<T>(FutureOr<DataResponse<T>> Function() closure) async {
    try {
      final d = await closure();
      return d;
    } on ArrkException catch (e, t) {
      if (e is! NetworkException && e is! ControlledException) {
        logger.severe(e.toFailure().message, e, t);
      }
      return DataResponse<T>(data: null, error: convertException(e), cause: e);
    } catch (e, t) {
      logger.severe(e, e, t);
      return DataResponse<T>(data: null, error: convertException(e), cause: e);
    }
  }

  /// Runs a write operation under the guard. Same conversion and logging
  /// rules as [runDataWithGuard], returning a [StatusResponse].
  @protected
  Future<StatusResponse> runStatusWithGuard(FutureOr<StatusResponse> Function() closure) async {
    try {
      final d = await closure();
      return d;
    } on ArrkException catch (e, t) {
      if (e is! NetworkException && e is! ControlledException) {
        logger.severe(e.toFailure().message, e, t);
      }
      return StatusResponse.failed(convertException(e), cause: e);
    } catch (e, t) {
      logger.severe(e, e, t);
      return StatusResponse.failed(convertException(e), cause: e);
    }
  }
}
