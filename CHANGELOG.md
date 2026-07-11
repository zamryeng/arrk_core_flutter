# Changelog

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
