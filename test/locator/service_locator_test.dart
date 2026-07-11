import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:arrk_core_flutter/locator.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// A simple injectable service for testing DI resolution.
abstract class _Counter {
  int get count;
  void increment();
}

class _ConcreteCounter implements _Counter {
  int _count = 0;
  @override
  int get count => _count;
  @override
  void increment() => _count++;
}

class _AnotherCounter implements _Counter {
  @override
  int get count => 99;
  @override
  void increment() {}
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Always reset GetIt fully between tests.
  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('configure', () {
    test('configure runs init and get<T> resolves registered type', () async {
      await ServiceLocator.configure((locator) {
        locator.registerSingleton<_Counter>(_ConcreteCounter());
      });

      final counter = ServiceLocator.get.get<_Counter>();
      expect(counter, isA<_ConcreteCounter>());
    });

    test('configure stores init so reset can re-run it', () async {
      var initRuns = 0;
      await ServiceLocator.configure((locator) {
        initRuns++;
        locator.registerSingleton<_Counter>(_ConcreteCounter());
      });
      expect(initRuns, 1);

      await ServiceLocator.reset();
      expect(initRuns, 2);
    });

    test('configure returns a usable ServiceLocator.get (GetIt.instance)', () async {
      await ServiceLocator.configure((locator) {
        locator.registerSingleton<_Counter>(_ConcreteCounter());
      });

      // get is GetIt.instance
      expect(ServiceLocator.get, same(GetIt.instance));
    });
  });

  group('reset', () {
    test('reset clears all registrations then re-runs init', () async {
      await ServiceLocator.configure((locator) {
        locator.registerSingleton<_Counter>(_ConcreteCounter()..increment());
      });

      final first = ServiceLocator.get.get<_Counter>();
      first.increment(); // count = 2 now (1 from init, 1 here)

      await ServiceLocator.reset();

      // After reset, a NEW instance is registered (fresh singleton from init).
      final second = ServiceLocator.get.get<_Counter>();
      expect(second.count, 1); // only the increment from configure
      expect(second, isNot(same(first)));
    });

    test('reset without prior configure does not throw', () async {
      // If configure was never called, _init is null. reset() should not throw.
      // We use a fresh GetIt state (tearDown resets it).
      // Just calling reset on a clean state should be safe.
      await expectLater(ServiceLocator.reset(), completes);
    });
  });

  group('resetInstance', () {
    test('resetInstance rebuilds a lazy singleton on next resolution', () async {
      await ServiceLocator.configure((locator) {
        locator.registerLazySingleton<_Counter>(() => _ConcreteCounter());
      });

      final first = ServiceLocator.get.get<_Counter>();
      first.increment(); // mutate to distinguish from a fresh instance
      expect(first.count, 1);

      ServiceLocator.resetInstance<_Counter>();

      final second = ServiceLocator.get.get<_Counter>();
      expect(second.count, 0); // fresh instance, mutation not carried over
      expect(second, isNot(same(first)));
    });
  });

  group('get', () {
    test('get<T> resolves the registered implementation', () async {
      await ServiceLocator.configure((locator) {
        locator.registerSingleton<_Counter>(_AnotherCounter());
      });

      final counter = ServiceLocator.get.get<_Counter>();
      expect(counter.count, 99);
    });

    test('get throws if type is not registered', () async {
      await ServiceLocator.configure((locator) {
        // Register nothing for _Counter.
      });

      expect(
        () => ServiceLocator.get.get<_Counter>(),
        throwsA(anything),
      );
    });
  });
}
