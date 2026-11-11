# Changelog

## 0.1.2

### Error codes (adapted from zamry_wallet)

- **`Failure.code`**: every failure carries a stable string to branch on. For a failure that came off the wire it is the server's error code, verbatim; failure types no response produced carry a client default — `ArrkFailureCodes.network` (`NETWORK_ERROR`), `.timeout` (`TIMEOUT`), `.serviceNotReady` (`SERVICE_NOT_READY`), `.unknown` (`UNKNOWN`). A server code always wins over the default. `Failure.toString()` shows it.
- **`ArrkException.code`** and a `@protected buildFailure(String? code)` template: `toFailure()` now always hands the exception's code to the failure it builds. Every shipped exception takes `code:`, and `ServiceNotInitializedException` / `ServiceInitException` do too. Product exceptions should `extends ArrkException` and implement `buildFailure`; a class that `implements ArrkException` must now also provide `code` and `buildFailure`.
- **`DioNetworkService` reads the code at the boundary**: error responses (5xx, 401/403, other 4xx) and success responses with `error: true` carry the body's `code` into the exception, via `errorCodeOf` (default `defaultErrorCodeOf`: `body['code']`, as a string). Pass your own `ErrorCodeReader` when the API nests it.
- `NetworkFailure` and `UnknownFailure` now `extends Failure` (were `implements`).

### `ArrkView(create:)` — view models built once

- **New `create:` factory on `ArrkView`**, called exactly once in the State's `initState`; that instance is the one provided and auto-disposed. Exactly one of `create:` / `model:` is required (asserted). Spelling: `create: ServiceLocator.get.call`, or `create: () => ServiceLocator.get<MyVm>(param1: dto)` for a flow VM.
- **Why:** `model:` is read once, so `model: ServiceLocator.get()` in a `build` method minted a new factory VM on every parent rebuild that was never used or disposed, leaking its subscriptions. The same held for route builders constructing VMs. `model:` stays for tests and for a caller that owns the instance (a `State` that built it once).
- Example: views create their VMs; routes hand the flow Dto to the view, not a VM.

### Fixes

- **The error interceptor no longer throws on a non-JSON error body** (an HTML error page): it yields an exception with no message and no code instead of a `FormatException` or cast error.

- **`arrk_lints/run.sh` can no longer pass without analyzing.** It skips tracked files deleted from the working tree (which made `dart analyze` exit with a usage error while the gate printed OK), and it fails when `dart analyze` prints no `Analyzing` line.
- **README:** `flutter analyze <file>` does not surface plugin diagnostics; only `dart analyze <file>` does. Products gate on `run.sh`.
- `capability_stateless` correction message says "the flow Dto" (was "a Draft").

## 0.1.1

Makes arrk the one rulebook for every arrk Flutter product. No product used 0.1.0, so the API changes below ship as a patch with no migration notes.

### API changes

- **Session is state, not events.** `ArrkSessionManager` (a `ChangeNotifier`) is gone, split in two:
  - `RequestHeadersProvider` (`network.dart`): the plumbing interface `DioNetworkService` reads headers from. `DioNetworkService(headersProvider: ...)` replaces `sessionManager:`.
  - `ArrkSessionRepo` (`session.dart`): the session as repo-owned state. `session` / `sessionStream` of an immutable `ArrkSession` (`deviceId`, `locale`, `country`, `isOpen`), with `open()`, `updateLocale()` and `updateCountry()` returning `StatusResponse`.
  - `SessionLocaleChanged` / `SessionCountryChanged` are deleted. Watch `sessionStream` instead.
- **Event bus split.** New `EventPublisher` (`fire`) and `EventStream` (`on<T>()`, `all`) interfaces; `ArrkEventBus` implements both and drops its `@singleton` annotation. Register one instance as all three types in DI (see `docs/01-getting-started.md`). Capabilities take `EventPublisher`; the reactions class takes `EventStream`.
- **`ArrkReactions<E>`**: base for the product's one subscriber. `start()` handles events one at a time, in order; a throwing `react` is logged and the next event still runs; `dispose()` cancels.
- **Messages: sink, channel and handler. `MessageDisplayHandler` is removed** (so is `NoopMessageHandler`). View models push `UserMessage`s (`UserMessageKind` error/success/warning/info, `text`, optional `heading`) onto a `MessageSink`; one `ArrkMessageChannel` (registered as itself, `MessageSink` and `MessageStream`) carries them; the app's one `ArrkMessageHandler` reads them and draws through `show()` on the root overlay. The handler merges a message with the same kind and text as one shown within `dedupeWindow` (default 2 s, read through `Clock`), shows messages from disposed and hidden screens, and survives a throwing `show`. A push with no listener is dropped.
- **`ArrkViewModel(MessageSink messageSink)`** — required; the `ServiceLocator` fallback is gone. `handleError` always pushes and records `lastFailure` (no `hasListeners` check); new `@protected` `showSuccess` / `showWarning` / `showInfo`; all four push even after `dispose()`. `ArrkPaginatedDataViewModel` passes the sink through. `FakeMessageSink` (`testing.dart`) records pushes.
- **`CachedStream`** takes a required `clearLocal` and gains `clear()`: drops the value, marks stale, deletes the local copy, re-hydrates on the next first listen, and stops a fetch that started before the clear from landing (its caller still gets the result). A new `stream` listener after `clear()` gets no replay of the old value.
- **Dependency ranges start at the latest releases** (10 Nov 2026): Dart `^3.13.7`, Flutter `>=3.47.8`, `go_router ^18.1.4`, `get_it ^9.3.0`, `injectable ^3.0.0`, `dio ^5.11.1`, `mime ^2.1.0`, `provider ^6.1.5+1`; `arrk_lints` on `analyzer ^14.7.0` and `analysis_server_plugin ^0.3.26`.

### Fixes

- `CachedStream.invalidate()` during an in-flight `refresh()` is no longer lost: the refresh still stores and emits its value, but the cache stays stale.
- `arrk_lints/run.sh` is executable.

### Docs

- README shape paragraph carries the 0.1.1 rules: capabilities, state ownership, state vs events, one publisher kind, one subscriber, services as plumbing, views navigate. A screen that must show a failed load calls `refresh()` and handles the response.
- `ArrkNavigator`: views navigate; view models never do.
- Install blocks name no repository URL; use the git URL you were given access to.

### Lints (`arrk_lints`)

- `event_bus_publisher_restriction`: covers `EventPublisher` too, and the session manager exemption is gone — `fire` is allowed only in `domain/use_cases/`.
- `no_change_notifier_outside_vm`: `ArrkViewModel` is the only carve-out.
- `no_event_fire_in_handler`: also flags any `EventPublisher` / `ArrkEventBus` reference inside an `ArrkReactions` subclass.
- `no_event_bus_in_repo`: also flags `EventPublisher` and `EventStream`.
- New `vm_uses_capabilities_only` (a VM holds no repo, service, event-bus type or message read-side type — only `MessageSink`), `capability_stateless`, `event_subscribe_restriction`, `message_stream_restriction` (C9: `MessageStream` / `ArrkMessageChannel` only in the `ArrkMessageHandler` subclass, DI and the composition root: `lib/di/`, `lib/app/`, `@module` classes).
- Baseline gate: `run.sh --update` writes `arrk_baseline.txt` (`rule|file|message`, no line numbers); `run.sh` fails only on violations not in it and reports fixed ones; `run.sh --report` counts per rule.

### Example

- Session as `ExampleSessionRepo` over an `ExampleRequestHeaders` service; one `AppReactions` mapping `GreetingSent` to a new activity feature's capability; an `OverlayMessageHandler` drawing toasts on the root overlay in place of the snackbar handler; VMs return results and views navigate; DI regenerated with injectable 3.

## 0.1.0

First release: the arrk Flutter core, extracted as a standalone package.

- View-model layer: `ArrkViewModel` (VmState machine, `handleError`/`handleErrorAndSetVmState`), `ArrkPaginatedDataViewModel`, `MessageDisplayHandler`.
- Views: `ArrkView` (lifecycle + provider host), `ArrkViewBuilder`, `ArrkViewSelector`.
- Data layer: `ArrkRepository` with `@protected` `runDataWithGuard`/`runStatusWithGuard`, `CachedStream` (demand-driven TTL cache), `Clock`/`SystemClock`, the typed `ArrkException` family.
- Responses: `Failure` hierarchy (incl. `ServiceNotReady`), `DataResponse<T>` with `cause`, `StatusResponse`.
- Events: `ArrkEvent` (plain abstract — products seal their own families), `ArrkEventBus`, `SessionLocaleChanged`/`SessionCountryChanged`.
- Navigation: `ArrkNavigator` over GoRouter, `ArrkRoute`, `ArrkExtrasCodec` base for web/deep-link extras round-trips, `DeepLinkRoute` redirect foundation.
- Network: `RestNetworkService`, `DioNetworkService` (typed-exception error interceptor, session-header auth), `JsonRequest`/`FormDataRequest`, `ApiEnvelope`. Compiles on web; multipart file upload is io-only at runtime.
- Services: `InitializableService` with the demand-driven surface — `ready` (memoized, starts init on first access), `status`/`currentStatus`, explicit `reinitialize()` after failure, `close()`.
- Session foundation: `ArrkSessionManager` (the one sanctioned ChangeNotifier outside view models), `ArrkUser`.
- DI: `ServiceLocator` facade over GetIt with `configure(init)` bootstrap seam.
- Testing: `FakeClock`, `FakeArrkEventBus`, `NoopMessageHandler`.
- `arrk_lints/`: analyzer plugin with 14 architecture rules — the 11 architecture-contract rules plus `no_repo_interfaces`, `no_try_catch_in_domain`, `no_cross_repo_calls`.
