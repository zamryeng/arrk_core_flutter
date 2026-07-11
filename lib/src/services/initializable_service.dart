import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../data/arrk_exceptions.dart';
import '../domain/failure.dart';

/// Lifecycle phase of an [InitializableService].
enum ServiceStatus {
  /// Never initialized, or torn down via [InitializableService.close].
  /// [idle] simply precedes first demand — the first [InitializableService.ready]
  /// access starts init.
  idle,

  /// [InitializableService.initialize] is running.
  initializing,

  /// Init finished successfully. Service is usable.
  ready,

  /// Init terminated with an error. Not usable until [InitializableService.reinitialize].
  failed,
}

/// Thrown when a service is awaited/accessed before init succeeded.
/// Maps to [ServiceNotReady] so repo guards convert it automatically.
class ServiceNotInitializedException extends ArrkException {
  const ServiceNotInitializedException(this.serviceName, {this.status, this.lastError});

  final String serviceName;
  final ServiceStatus? status;
  final Object? lastError;

  @override
  Failure toFailure() =>
      ServiceNotReady(serviceName: serviceName, status: status, lastError: lastError);
}

/// Thrown from inside an init body when initialization fails, and used as the
/// null-error fallback when a failed service's [InitializableService.ready]
/// is awaited. [message] is surfaced verbatim as the [ServiceNotReady]
/// failure message.
class ServiceInitException extends ArrkException {
  const ServiceInitException(this.serviceName, {this.message, this.cause});

  final String serviceName;
  final String? message;
  final Object? cause;

  @override
  Failure toFailure() =>
      ServiceNotReady(serviceName: serviceName, lastError: cause, message: message);
}

/// Base class for long-init services (SDK wrappers, engines with warm-up).
///
/// One type: the public lifecycle surface AND the plumbing. Concrete services
/// `extends` this (directly or via a domain abstract subclass) and implement
/// their init body in [initialize]; the base runs it through [trackInit] on
/// first [ready] access and on [reinitialize].
///
/// The consumer surface is [ready] / [status] / [reinitialize]: every public
/// service method self-awaits [ready]; write paths short-circuit with a
/// [ServiceNotReady] failure when [status] is [ServiceStatus.failed].
abstract class InitializableService {
  /// Display name used in errors (e.g. "Payments engine").
  String get serviceName;

  final BehaviorSubject<ServiceStatus> _status = BehaviorSubject<ServiceStatus>.seeded(
    ServiceStatus.idle,
  );
  Future<void>? _initFuture;
  Object? _lastError;

  /// Single async readiness gate, memoized: first access starts init; all
  /// callers share the in-flight future. Correct in every state, never hangs:
  ///  - idle          → starts [initialize] (via [trackInit]) and awaits it
  ///  - initializing  → awaits the in-flight init
  ///  - ready         → completes
  ///  - failed        → throws [lastError], or [ServiceInitException] if none;
  ///                    retry is explicit via [reinitialize], never implicit
  Future<void> get ready {
    switch (currentStatus) {
      case ServiceStatus.ready:
        return Future<void>.value();
      case ServiceStatus.failed:
        return Future<void>.error(_lastError ?? ServiceInitException(serviceName));
      case ServiceStatus.idle:
      case ServiceStatus.initializing:
        return trackInit(initialize);
    }
  }

  /// Live status. Behavior-subject semantics: replays the current value on
  /// subscribe, then every transition. Always agrees with [currentStatus].
  Stream<ServiceStatus> get status => _status.stream;

  /// Synchronous snapshot. Never null — [ServiceStatus.idle] before init.
  ServiceStatus get currentStatus => _status.value;

  /// Single source of truth for readiness.
  bool get isInitialized => currentStatus == ServiceStatus.ready;

  /// The most recent init error, or null.
  Object? get lastError => _lastError;

  /// Explicit retry after failure: drains any in-flight init, resets to
  /// [ServiceStatus.idle], then runs [initialize] again through [trackInit].
  /// Works from any state — a reinitialize while ready forces a fresh init.
  Future<void> reinitialize() async {
    final pending = _initFuture;
    if (pending != null) {
      await pending.catchError((_) {});
    }
    _lastError = null;
    _initFuture = null;
    _status.add(ServiceStatus.idle);
    return trackInit(initialize);
  }

  /// The init body a subclass implements. Never called directly by
  /// consumers — the base runs it through [trackInit] on first [ready]
  /// access and on [reinitialize]. Throw [ServiceInitException] (or let the
  /// underlying error propagate) on failure.
  @protected
  Future<void> initialize();

  /// Wraps an init body in the status lifecycle. Idempotent:
  ///   ready        → no-op
  ///   initializing → shares the in-flight future
  ///   idle/failed  → runs [body]
  ///
  /// Because of the `ready` no-op, services do NOT need an "already
  /// initialized" guard.
  @protected
  Future<void> trackInit(Future<void> Function() body) {
    switch (currentStatus) {
      case ServiceStatus.ready:
        return Future<void>.value();
      case ServiceStatus.initializing:
        return _initFuture ?? Future<void>.value();
      case ServiceStatus.idle:
      case ServiceStatus.failed:
        _status.add(ServiceStatus.initializing);
        final tracked = _runInit(body);
        _initFuture = tracked;
        return tracked;
    }
  }

  Future<void> _runInit(Future<void> Function() body) async {
    try {
      await body();
      _lastError = null;
      _status.add(ServiceStatus.ready);
    } catch (e) {
      _lastError = e;
      _status.add(ServiceStatus.failed);
      rethrow;
    } finally {
      _initFuture = null;
    }
  }

  /// Teardown → terminal [ServiceStatus.idle].
  ///
  /// Overrides MUST call `super.close()` FIRST, then release their resources.
  /// Calling super first drains any in-flight init (so teardown never yanks a
  /// handle mid-initialization) and flips status to [ServiceStatus.idle], so
  /// concurrent callers are rejected by [ready] before the resources
  /// disappear.
  @mustCallSuper
  Future<void> close() async {
    final pending = _initFuture;
    if (pending != null) {
      await pending.catchError((_) {});
    }
    _lastError = null;
    _initFuture = null;
    _status.add(ServiceStatus.idle);
  }

  /// Closes the status stream. Real disposal only (rare — services are
  /// singletons). Not part of [close].
  Future<void> disposeStatus() => _status.close();
}
