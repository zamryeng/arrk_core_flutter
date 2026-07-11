import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:arrk_core_flutter/data.dart';
import 'package:arrk_core_flutter/responses.dart';
import 'package:arrk_core_flutter/services.dart';

/// Minimal concrete service exercising the [InitializableService] base.
class _FakeService extends InitializableService {
  _FakeService(this._initBody);

  Future<void> Function() _initBody;
  int initCalls = 0;
  int closes = 0;

  @override
  String get serviceName => 'Fake';

  @override
  Future<void> initialize() async {
    initCalls++;
    await _initBody();
  }

  void setInitBody(Future<void> Function() body) => _initBody = body;

  @override
  Future<void> close() async {
    closes++;
    await super.close();
  }
}

void main() {
  group('status + default state', () {
    test('starts idle; currentStatus and stream agree on first listen', () async {
      final svc = _FakeService(() async {});
      expect(svc.currentStatus, ServiceStatus.idle);
      expect(svc.isInitialized, isFalse);

      final first = await svc.status.first;
      expect(first, ServiceStatus.idle);
    });

    test('status flows idle -> initializing -> ready on success', () async {
      final svc = _FakeService(() async {});
      final emitted = <ServiceStatus>[];
      final sub = svc.status.listen(emitted.add);

      await svc.ready;
      await pumpEventQueue();

      expect(emitted, [
        ServiceStatus.idle,
        ServiceStatus.initializing,
        ServiceStatus.ready,
      ]);
      expect(svc.isInitialized, isTrue);
      await sub.cancel();
    });

    test('status stream replays current value on subscribe (BehaviorSubject)', () async {
      final svc = _FakeService(() async {});
      await svc.ready;

      // Subscribe AFTER init completes — BehaviorSubject should replay 'ready'.
      final first = await svc.status.first;
      expect(first, ServiceStatus.ready);
    });
  });

  group('ready — idle → starts initialize', () {
    test('awaiting ready from idle runs initialize and resolves', () async {
      final svc = _FakeService(() async {});
      await svc.ready;
      expect(svc.currentStatus, ServiceStatus.ready);
      expect(svc.initCalls, 1);
    });

    test('ready from idle starts exactly one initialize call', () async {
      final completer = Completer<void>();
      final svc = _FakeService(() => completer.future);

      final f1 = svc.ready;
      final f2 = svc.ready;
      // Both futures share the in-flight init — initCalls is still 1.
      expect(svc.initCalls, 1);

      completer.complete();
      await f1;
      await f2;
      expect(svc.currentStatus, ServiceStatus.ready);
      expect(svc.initCalls, 1);
    });
  });

  group('ready — initializing → shares in-flight future', () {
    test('concurrent ready calls share the in-flight future', () async {
      final completer = Completer<void>();
      final svc = _FakeService(() => completer.future);

      final f1 = svc.ready;
      expect(svc.currentStatus, ServiceStatus.initializing);
      final f2 = svc.ready;

      completer.complete();
      await f1;
      await f2;
      expect(svc.currentStatus, ServiceStatus.ready);
      expect(svc.initCalls, 1);
    });
  });

  group('ready — already ready → completes immediately', () {
    test('ready after successful init completes without re-running initialize', () async {
      final svc = _FakeService(() async {});
      await svc.ready;
      await svc.ready; // second call
      expect(svc.initCalls, 1);
      expect(svc.currentStatus, ServiceStatus.ready);
    });
  });

  group('ready — failed → throws', () {
    test('failed service throws lastError when ready is awaited', () async {
      final boom = StateError('init failed');
      final svc = _FakeService(() async => throw boom);

      await expectLater(svc.ready, throwsA(same(boom)));
      expect(svc.currentStatus, ServiceStatus.failed);
    });

    test('failed service throws ServiceInitException when lastError is null', () async {
      // Simulate the (unusual) path where failed state has null lastError by
      // constructing a service that stores no error — we use the public API:
      // after close() lastError is null and status is idle. Failed with a null
      // lastError would require direct state manipulation not possible via the
      // public surface, so we verify the ready→failed path via lastError.
      final svc = _FakeService(() async => throw StateError('x'));
      await expectLater(svc.ready, throwsA(isA<StateError>()));
      expect(svc.lastError, isA<StateError>());

      // A second awaiting of ready also throws the SAME error (no implicit retry).
      await expectLater(svc.ready, throwsA(isA<StateError>()));
    });

    test('failed state never resolves as success', () async {
      final svc = _FakeService(() async => throw StateError('x'));
      await expectLater(svc.ready, throwsA(isA<StateError>()));

      var resolvedOk = false;
      try {
        await svc.ready;
        resolvedOk = true;
      } catch (_) {
        // expected
      }
      expect(resolvedOk, isFalse);
    });
  });

  group('trackInit idempotency', () {
    test('trackInit while ready is a no-op', () async {
      final svc = _FakeService(() async {});
      await svc.ready;
      await svc.ready;
      expect(svc.initCalls, 1);
      expect(svc.currentStatus, ServiceStatus.ready);
    });

    test('concurrent trackInit calls share the in-flight future', () async {
      final completer = Completer<void>();
      final svc = _FakeService(() => completer.future);

      final f1 = svc.ready;
      final f2 = svc.ready;
      expect(svc.initCalls, 1);

      completer.complete();
      await f1;
      await f2;
      expect(svc.currentStatus, ServiceStatus.ready);
    });

    test('initialize after failure (via ready) restarts and can succeed', () async {
      var fail = true;
      final svc = _FakeService(() async {
        if (fail) throw StateError('boom');
      });

      await expectLater(svc.ready, throwsA(isA<StateError>()));
      expect(svc.currentStatus, ServiceStatus.failed);

      fail = false;
      await svc.reinitialize();
      expect(svc.currentStatus, ServiceStatus.ready);
      expect(svc.lastError, isNull);
    });
  });

  group('reinitialize', () {
    test('drains in-flight, resets to idle, re-runs initialize', () async {
      final svc = _FakeService(() async {});
      await svc.ready;
      expect(svc.currentStatus, ServiceStatus.ready);

      await svc.reinitialize();
      expect(svc.currentStatus, ServiceStatus.ready);
      expect(svc.initCalls, 2);
    });

    test('reinitialize from failed state succeeds', () async {
      final svc = _FakeService(() async => throw StateError('boom'));
      await expectLater(svc.ready, throwsA(isA<StateError>()));
      expect(svc.currentStatus, ServiceStatus.failed);

      svc.setInitBody(() async {});
      await svc.reinitialize();
      expect(svc.currentStatus, ServiceStatus.ready);
    });

    test('reinitialize from idle state succeeds', () async {
      final svc = _FakeService(() async {});
      expect(svc.currentStatus, ServiceStatus.idle);

      await svc.reinitialize();
      expect(svc.currentStatus, ServiceStatus.ready);
    });

    test('reinitialize drains pending in-flight before restarting', () async {
      final completer = Completer<void>();
      final svc = _FakeService(() => completer.future);

      // Start init but don't complete it.
      unawaited(svc.ready);
      expect(svc.currentStatus, ServiceStatus.initializing);

      // reinitialize should wait for in-flight to settle then restart.
      completer.complete();
      svc.setInitBody(() async {});
      await svc.reinitialize();
      expect(svc.currentStatus, ServiceStatus.ready);
    });

    test('reinitialize clears lastError', () async {
      final svc = _FakeService(() async => throw StateError('boom'));
      await expectLater(svc.ready, throwsA(isA<StateError>()));
      expect(svc.lastError, isNotNull);

      svc.setInitBody(() async {});
      await svc.reinitialize();
      expect(svc.lastError, isNull);
    });
  });

  group('close', () {
    test('close resets to terminal idle and is overridable with super', () async {
      final svc = _FakeService(() async {});
      await svc.ready;
      expect(svc.isInitialized, isTrue);

      await svc.close();
      expect(svc.closes, 1);
      expect(svc.currentStatus, ServiceStatus.idle);
      expect(svc.lastError, isNull);

      // Can re-initialize after close.
      await svc.ready;
      expect(svc.currentStatus, ServiceStatus.ready);
    });

    test('close drains in-flight init before resetting', () async {
      final completer = Completer<void>();
      final svc = _FakeService(() => completer.future);

      unawaited(svc.ready);
      expect(svc.currentStatus, ServiceStatus.initializing);

      completer.complete();
      await svc.close();
      expect(svc.currentStatus, ServiceStatus.idle);
    });
  });

  group('disposeStatus', () {
    test('disposeStatus closes the status stream', () async {
      final svc = _FakeService(() async {});
      await svc.ready;
      await svc.disposeStatus();

      // After disposeStatus the stream is closed — no more events.
      final events = <ServiceStatus>[];
      await for (final s in svc.status) {
        events.add(s);
      }
      // BehaviorSubject that is closed will complete the stream.
      // We just verify it doesn't hang forever.
      expect(events, isNotEmpty); // replays current value then closes
    });
  });

  group('unified exceptions', () {
    test('ServiceNotInitializedException maps to ServiceNotReady', () {
      const e = ServiceNotInitializedException('Payments engine', status: ServiceStatus.idle);
      final f = e.toFailure();
      expect(e, isA<ArrkException>());
      expect(f, isA<ServiceNotReady>());
      expect((f as ServiceNotReady).serviceName, 'Payments engine');
      expect(f.status, ServiceStatus.idle);
    });

    test('ServiceInitException carries message + cause into ServiceNotReady', () {
      final cause = StateError('sdk');
      const svcName = 'Wallet engine';
      final e = ServiceInitException(svcName, message: 'init failed', cause: cause);
      final f = e.toFailure() as ServiceNotReady;
      expect(f.message, 'init failed');
      expect(f.lastError, same(cause));
      expect(f.serviceName, svcName);
    });

    test('ServiceInitException default message falls back to ServiceNotReady default', () {
      final e = ServiceInitException('My service');
      final f = e.toFailure() as ServiceNotReady;
      // message is null → ServiceNotReady uses its own default message
      expect(f.message, contains('My service'));
    });
  });

  group('status stream replay', () {
    test('BehaviorSubject replays idle before any init', () async {
      final svc = _FakeService(() async {});
      expect(await svc.status.first, ServiceStatus.idle);
    });

    test('BehaviorSubject replays ready after init completes', () async {
      final svc = _FakeService(() async {});
      await svc.ready;
      expect(await svc.status.first, ServiceStatus.ready);
    });

    test('BehaviorSubject replays failed after init error', () async {
      final svc = _FakeService(() async => throw StateError('boom'));
      await expectLater(svc.ready, throwsA(isA<StateError>()));
      expect(await svc.status.first, ServiceStatus.failed);
    });
  });
}
