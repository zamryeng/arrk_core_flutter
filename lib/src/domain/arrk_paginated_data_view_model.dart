import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'arrk_responses.dart';
import 'arrk_view_model.dart';

/// View model base for paginated lists.
///
/// Handles the common pagination mechanics — busy state, error handling,
/// page tracking, data accumulation — around one abstract [fetchData].
///
/// ```dart
/// class ActivityListViewModel extends ArrkPaginatedDataViewModel<Activity> {
///   @override
///   Future<DataResponse<Iterable<Activity>>> fetchData(int page) =>
///       _activityRepo.getActivities(page: page);
/// }
/// ```
abstract class ArrkPaginatedDataViewModel<T> extends ArrkViewModel {
  int _page = 1;

  bool _reachedMax = false;

  /// Accumulates items from every loaded page. Protected so subclasses can
  /// run custom logic over it; external readers use [data].
  @protected
  final dataList = <T>[];

  /// True only while there is an error AND no data is held — an error during
  /// [fetchMore] must not blank out an already-rendered list.
  @override
  bool get hasEncounteredError => super.hasEncounteredError && !hasData;

  /// True once at least one item has been loaded.
  bool get hasData => data.isNotEmpty;

  /// The current page number (1-based).
  int get page => _page;

  /// True when a page returned no items — the end of the data.
  bool get noMorePages => _reachedMax;

  /// Read-only view of every loaded item.
  UnmodifiableListView<T> get data => UnmodifiableListView(dataList);

  /// Fetches one page. Implementations return the repo's [DataResponse]
  /// directly — the base class handles state and errors.
  Future<DataResponse<Iterable<T>>> fetchData(int page);

  /// Resets to page 1, clears held data on success, and fetches. The
  /// pull-to-refresh entry point.
  Future<void> refresh() {
    _page = 1;
    _reachedMax = false;
    return _fetchData();
  }

  /// Fetches the next page and appends. The scroll-to-bottom entry point.
  Future<void> fetchMore() {
    return _fetchData();
  }

  Future<void> _fetchData() async {
    if (isBusy || _reachedMax) return;
    setState(VmState.busy);

    final fetched = await fetchData(_page);
    if (fetched.hasError) {
      handleErrorAndSetVmState(fetched.error!);
    } else {
      if (_page == 1) dataList.clear();
      final data = fetched.data!;
      if (data.isNotEmpty) {
        dataList.addAll(data);

        _page++;
      } else {
        _reachedMax = true;
      }
      setState(VmState.none);
    }
  }
}
