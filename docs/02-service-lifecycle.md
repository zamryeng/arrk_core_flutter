---
title: Service lifecycle
updated_at: 2026-07-11
---

[← Back to docs index](00-index.md)

# Service lifecycle — `InitializableService`

For services with a real warm-up (SDK handles, engines, anything that can fail to come up). Cheap wrappers don't need it.

## The surface

```dart
class PaymentsEngine extends InitializableService {
  @override
  String get serviceName => 'Payments engine';

  @override
  Future<void> initialize() async {
    _handle = await Sdk.connect(...);   // throw on failure — the base tracks it
  }
}
```

- `ready` — the single readiness gate, memoized. First access starts `initialize()`; concurrent awaiters share the in-flight future. When the service is `failed`, `ready` **throws** the stored error — it never retries implicitly.
- `status` / `currentStatus` — live stream (replays current on subscribe) and sync snapshot: `idle → initializing → ready | failed`.
- `reinitialize()` — the explicit retry. Drains any in-flight init, resets to `idle`, runs `initialize()` again. UI retry affordances wire to this.
- `close()` — teardown back to `idle`. Overrides call `super.close()` FIRST, then release resources.

## How the layers consume it

Every public method of the service self-awaits `ready`. Repos guard the rest:

```dart
Future<StatusResponse> submitPayment(PaymentDto dto) => runStatusWithGuard(() async {
  if (_engine.currentStatus == ServiceStatus.failed) {
    throw ServiceNotInitializedException(_engine.serviceName,
        status: _engine.currentStatus, lastError: _engine.lastError);
  }
  await _engine.ready;
  ...
});
```

The guard converts that exception to a `ServiceNotReady` failure; the UI maps `ServiceNotReady` to a retry affordance wired to `reinitialize()` — never a generic error toast.

---

[← Back to docs index](00-index.md)
