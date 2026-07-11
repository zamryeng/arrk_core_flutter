import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:arrk_core_flutter/responses.dart';
import 'package:arrk_core_flutter/viewmodel.dart';
import 'package:arrk_core_flutter/testing.dart';

/// Recording [MessageDisplayHandler] that captures calls for assertions.
class _RecordingMessageHandler implements MessageDisplayHandler {
  final List<String> errors = <String>[];
  final List<String> successes = <String>[];
  final List<String> warnings = <String>[];
  final List<String> infos = <String>[];

  @override
  void showError(String message, [String? heading]) => errors.add(message);
  @override
  void showSuccess(String message, [String? heading]) => successes.add(message);
  @override
  void showWarning(String message, [String? heading]) => warnings.add(message);
  @override
  void showInfo(String message, [String? heading]) => infos.add(message);
}

/// Minimal concrete VM for testing the base-class surface.
class _TestViewModel extends ArrkViewModel {
  _TestViewModel([super.handler]);

  void publicSetState([VmState? state]) => setState(state);

  void publicHandleError(Failure failure, [String? heading]) =>
      handleError(failure, heading);

  void publicHandleErrorAndSetVmState(Failure failure, [String? heading]) =>
      handleErrorAndSetVmState(failure, heading);
}

void main() {
  late _RecordingMessageHandler handler;
  late _TestViewModel vm;

  setUp(() {
    handler = _RecordingMessageHandler();
    vm = _TestViewModel(handler);
  });

  tearDown(() {
    vm.dispose();
  });

  group('VmState transitions via setState', () {
    test('initial state is none', () {
      expect(vm.viewState, VmState.none);
    });

    test('setState changes the viewState', () {
      vm.publicSetState(VmState.busy);
      expect(vm.viewState, VmState.busy);
    });

    test('setState with null leaves state unchanged', () {
      vm.publicSetState(VmState.busy);
      vm.publicSetState(null);
      expect(vm.viewState, VmState.busy);
    });

    test('setState without arg notifies listeners without changing state', () {
      var notified = 0;
      vm.addListener(() => notified++);
      vm.publicSetState(VmState.busy);
      notified = 0; // reset after the busy notification

      vm.publicSetState(null);
      expect(notified, 1);
      expect(vm.viewState, VmState.busy);
    });

    test('setState cycles through all VmState values', () {
      for (final state in VmState.values) {
        vm.publicSetState(state);
        expect(vm.viewState, state);
      }
    });
  });

  group('hasEncounteredError', () {
    test('false when state is none', () {
      expect(vm.hasEncounteredError, isFalse);
    });

    test('false when state is busy', () {
      vm.publicSetState(VmState.busy);
      expect(vm.hasEncounteredError, isFalse);
    });

    test('true when state is error', () {
      vm.publicSetState(VmState.error);
      expect(vm.hasEncounteredError, isTrue);
    });

    test('true when state is noConnection', () {
      vm.publicSetState(VmState.noConnection);
      expect(vm.hasEncounteredError, isTrue);
    });
  });

  group('isBusy', () {
    test('false initially', () {
      expect(vm.isBusy, isFalse);
    });

    test('true when state is busy', () {
      vm.publicSetState(VmState.busy);
      expect(vm.isBusy, isTrue);
    });

    test('false for other states', () {
      for (final state in VmState.values.where((s) => s != VmState.busy)) {
        vm.publicSetState(state);
        expect(vm.isBusy, isFalse);
      }
    });
  });

  group('handleErrorAndSetVmState', () {
    test('NetworkFailure → noConnection state', () {
      vm.addListener(() {});
      vm.publicHandleErrorAndSetVmState(NetworkFailure());
      expect(vm.viewState, VmState.noConnection);
    });

    test('ServerFailure → error state', () {
      vm.addListener(() {});
      vm.publicHandleErrorAndSetVmState(ServerFailure());
      expect(vm.viewState, VmState.error);
    });

    test('InputFailure → error state', () {
      vm.addListener(() {});
      vm.publicHandleErrorAndSetVmState(InputFailure(message: 'bad'));
      expect(vm.viewState, VmState.error);
    });

    test('UnknownFailure → error state', () {
      vm.addListener(() {});
      vm.publicHandleErrorAndSetVmState(UnknownFailure());
      expect(vm.viewState, VmState.error);
    });

    test('TimeoutFailure → error state', () {
      vm.addListener(() {});
      vm.publicHandleErrorAndSetVmState(TimeoutFailure());
      expect(vm.viewState, VmState.error);
    });
  });

  group('handleError', () {
    test('records lastFailure when VM has listeners', () {
      final failure = ServerFailure(message: 'oops');
      vm.addListener(() {});
      vm.publicHandleError(failure);
      expect(vm.lastFailure, same(failure));
    });

    test('shows message when VM has listeners', () {
      vm.addListener(() {});
      vm.publicHandleError(ServerFailure(message: 'server down'));
      expect(handler.errors, contains('server down'));
    });

    test('does NOT record lastFailure when VM has no listeners', () {
      final failure = ServerFailure(message: 'silent');
      // No listeners added.
      vm.publicHandleError(failure);
      expect(vm.lastFailure, isNull);
    });

    test('does NOT show message when VM has no listeners', () {
      vm.publicHandleError(ServerFailure(message: 'should not show'));
      expect(handler.errors, isEmpty);
    });

    test('updates lastFailure on each call', () {
      vm.addListener(() {});
      final f1 = ServerFailure(message: 'first');
      final f2 = InputFailure(message: 'second');
      vm.publicHandleError(f1);
      vm.publicHandleError(f2);
      expect(vm.lastFailure, same(f2));
    });
  });

  group('dispose', () {
    test('setState after dispose is a no-op (no throw)', () {
      // Use a local VM: the shared one is disposed by tearDown and
      // ChangeNotifier asserts on double dispose in debug mode.
      final localVm = _TestViewModel(handler);
      localVm.addListener(() {});
      localVm.dispose();
      // Should not throw or notify.
      localVm.publicSetState(VmState.busy);
      expect(localVm.viewState, VmState.busy); // state updated but no notify
    });
  });

  group('constructor resolves MessageDisplayHandler from ServiceLocator', () {
    tearDown(() async {
      await GetIt.instance.reset();
    });

    test('resolves NoopMessageHandler registered in GetIt', () {
      GetIt.instance.registerSingleton<MessageDisplayHandler>(NoopMessageHandler());

      final resolvedVm = _TestViewModel(); // no explicit handler
      resolvedVm.addListener(() {});
      // Should not throw — handler is resolved from DI.
      resolvedVm.publicHandleError(ServerFailure(message: 'test'));
      resolvedVm.dispose();
    });
  });

  group('notifications', () {
    test('setState notifies listeners when present', () {
      var notified = 0;
      vm.addListener(() => notified++);
      vm.publicSetState(VmState.busy);
      expect(notified, 1);
    });

    test('setState does not notify when no listeners', () {
      // No listener added; just ensure no throw.
      vm.publicSetState(VmState.busy);
    });

    test('listener is removed properly', () {
      var notified = 0;
      void listener() => notified++;
      vm.addListener(listener);
      vm.publicSetState(VmState.busy);
      expect(notified, 1);

      vm.removeListener(listener);
      vm.publicSetState(VmState.none);
      expect(notified, 1);
    });
  });
}
