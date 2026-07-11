import 'dart:async';
import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:arrk_core_flutter/responses.dart';
import 'package:arrk_core_flutter/viewmodel.dart';
import 'package:arrk_core_flutter/testing.dart';

// ---------------------------------------------------------------------------
// DI bootstrap helpers
// ---------------------------------------------------------------------------

void _bootstrapNoop() {
  if (!GetIt.instance.isRegistered<MessageDisplayHandler>()) {
    GetIt.instance.registerSingleton<MessageDisplayHandler>(NoopMessageHandler());
  }
}

// ---------------------------------------------------------------------------
// Test VMs
// ---------------------------------------------------------------------------

/// Scripted fetch: callers push [DataResponse]s onto the queue and
/// [_ScriptedPaginatedVm] pops them in order.
class _ScriptedPaginatedVm extends ArrkPaginatedDataViewModel<String> {
  final Queue<DataResponse<Iterable<String>>> script =
      Queue<DataResponse<Iterable<String>>>();

  int fetchCalls = 0;

  void enqueue(DataResponse<Iterable<String>> response) =>
      script.addLast(response);

  @override
  Future<DataResponse<Iterable<String>>> fetchData(int page) async {
    fetchCalls++;
    if (script.isEmpty) {
      throw StateError('No more scripted responses for page $page');
    }
    return script.removeFirst();
  }
}

/// VM that holds a fetch in progress via a Completer, for testing busy guard.
class _SlowPaginatedVm extends ArrkPaginatedDataViewModel<String> {
  late Completer<void> completer;
  int fetchCalls = 0;

  @override
  Future<DataResponse<Iterable<String>>> fetchData(int page) async {
    fetchCalls++;
    await completer.future;
    return DataResponse<Iterable<String>>(data: const <String>['item']);
  }
}

// ---------------------------------------------------------------------------
// Factories
// ---------------------------------------------------------------------------

/// Convenience factory for success responses.
DataResponse<Iterable<String>> _success(List<String> items) =>
    DataResponse<Iterable<String>>(data: items);

/// Convenience factory for error responses.
DataResponse<Iterable<String>> _error(Failure failure) =>
    DataResponse<Iterable<String>>(error: failure);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _ScriptedPaginatedVm vm;

  setUp(() {
    _bootstrapNoop();
    vm = _ScriptedPaginatedVm();
    // Add a listener so handleError actually records failures.
    vm.addListener(() {});
  });

  tearDown(() async {
    vm.dispose();
    await GetIt.instance.reset();
  });

  group('refresh', () {
    test('resets to page 1 and fetches', () async {
      vm.enqueue(_success(['a', 'b']));
      await vm.refresh();
      expect(vm.page, 2); // incremented to next page after success
      expect(vm.data.toList(), ['a', 'b']);
      expect(vm.fetchCalls, 1);
    });

    test('clears previous data on successful refresh', () async {
      vm.enqueue(_success(['a', 'b']));
      await vm.refresh();
      expect(vm.data.toList(), ['a', 'b']);

      // Refresh replaces with new data.
      vm.enqueue(_success(['c', 'd']));
      await vm.refresh();
      expect(vm.data.toList(), ['c', 'd']);
    });

    test('resets page to 1 before fetching even after fetchMore', () async {
      // Load two pages.
      vm.enqueue(_success(['a']));
      await vm.refresh();
      vm.enqueue(_success(['b']));
      await vm.fetchMore();
      expect(vm.page, 3);

      // Refresh should reset to page 1 and replace data.
      vm.enqueue(_success(['fresh']));
      await vm.refresh();
      expect(vm.page, 2);
      expect(vm.data.toList(), ['fresh']);
    });

    test('sets state to none after successful refresh', () async {
      vm.enqueue(_success(['item']));
      await vm.refresh();
      expect(vm.viewState, VmState.none);
    });

    test('resets noMorePages flag on refresh', () async {
      vm.enqueue(_success([])); // empty → noMorePages
      await vm.refresh();
      expect(vm.noMorePages, isTrue);

      vm.enqueue(_success(['a']));
      await vm.refresh();
      expect(vm.noMorePages, isFalse);
    });
  });

  group('fetchMore', () {
    test('appends items and increments page', () async {
      vm.enqueue(_success(['a']));
      await vm.refresh();
      expect(vm.page, 2);

      vm.enqueue(_success(['b', 'c']));
      await vm.fetchMore();
      expect(vm.data.toList(), ['a', 'b', 'c']);
      expect(vm.page, 3);
    });

    test('does not clear existing data on subsequent pages', () async {
      vm.enqueue(_success(['a']));
      await vm.refresh();

      vm.enqueue(_success(['b']));
      await vm.fetchMore();
      expect(vm.data, contains('a'));
      expect(vm.data, contains('b'));
    });
  });

  group('empty page', () {
    test('sets noMorePages when page returns empty', () async {
      vm.enqueue(_success(['a']));
      await vm.refresh();
      expect(vm.noMorePages, isFalse);

      vm.enqueue(_success([]));
      await vm.fetchMore();
      expect(vm.noMorePages, isTrue);
    });

    test('does not increment page when empty result', () async {
      vm.enqueue(_success(['a']));
      await vm.refresh();
      final pageBefore = vm.page;

      vm.enqueue(_success([]));
      await vm.fetchMore();
      expect(vm.page, pageBefore); // unchanged
    });

    test('stops further fetches after noMorePages', () async {
      vm.enqueue(_success(['a']));
      await vm.refresh();
      vm.enqueue(_success([]));
      await vm.fetchMore();
      expect(vm.noMorePages, isTrue);

      // This call should be a no-op (no more items in script needed).
      await vm.fetchMore();
      expect(vm.fetchCalls, 2); // no third call
    });
  });

  group('error path', () {
    test('calls handleErrorAndSetVmState on failure', () async {
      vm.enqueue(_error(ServerFailure()));
      await vm.refresh();
      expect(vm.viewState, VmState.error);
    });

    test('hasEncounteredError is true when there is error AND no data', () async {
      vm.enqueue(_error(ServerFailure()));
      await vm.refresh();
      expect(vm.hasData, isFalse);
      expect(vm.hasEncounteredError, isTrue);
    });

    test('hasEncounteredError is false when there is error but data exists', () async {
      // Load some data first.
      vm.enqueue(_success(['a', 'b']));
      await vm.refresh();

      // Next fetch fails.
      vm.enqueue(_error(ServerFailure()));
      await vm.fetchMore();
      expect(vm.hasData, isTrue);
      expect(vm.hasEncounteredError, isFalse);
    });

    test('NetworkFailure sets noConnection state', () async {
      vm.enqueue(_error(NetworkFailure()));
      await vm.refresh();
      expect(vm.viewState, VmState.noConnection);
    });

    test('lastFailure is set after error', () async {
      final failure = ServerFailure(message: 'bad');
      vm.enqueue(_error(failure));
      await vm.refresh();
      expect(vm.lastFailure, same(failure));
    });
  });

  group('busy guard', () {
    test('concurrent _fetchData is a no-op while busy', () async {
      final slowVm = _SlowPaginatedVm()..addListener(() {});
      slowVm.completer = Completer<void>();

      final f1 = slowVm.refresh();
      expect(slowVm.isBusy, isTrue);

      // Second call while busy should be a no-op.
      await slowVm.fetchMore();
      expect(slowVm.fetchCalls, 1);

      slowVm.completer.complete();
      await f1;
      slowVm.dispose();
    });

    test('fetchMore while busy is a no-op', () async {
      final slowVm = _SlowPaginatedVm()..addListener(() {});
      slowVm.completer = Completer<void>();

      unawaited(slowVm.refresh());
      expect(slowVm.isBusy, isTrue);

      final moreFuture = slowVm.fetchMore();
      await moreFuture; // should complete immediately (no-op)

      expect(slowVm.fetchCalls, 1);
      slowVm.completer.complete();
      slowVm.dispose();
    });
  });

  group('hasData', () {
    test('false initially', () {
      expect(vm.hasData, isFalse);
    });

    test('true after successful fetch with items', () async {
      vm.enqueue(_success(['x']));
      await vm.refresh();
      expect(vm.hasData, isTrue);
    });

    test('false after empty fetch', () async {
      vm.enqueue(_success([]));
      await vm.refresh();
      expect(vm.hasData, isFalse);
    });
  });

  group('data is an unmodifiable view', () {
    test('data cannot be modified directly', () async {
      vm.enqueue(_success(['a']));
      await vm.refresh();

      expect(() => vm.data.add('b'), throwsUnsupportedError);
    });
  });
}
