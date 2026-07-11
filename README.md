# arrk_core_flutter

Arrk's Flutter core. The base classes and plumbing every arrk Flutter product consumes — view models, views, repositories, response types, events, navigation, network, service lifecycle, session, and DI wiring — plus `arrk_lints/`, the analyzer plugin that enforces the architecture statically.

Products consume this package; they never own copies of it. The law for how each type is used lives in the arrk corpus (`doctrine/flutter/`), not here — this README covers the mechanics.

## Install

```yaml
# pubspec.yaml
dependencies:
  arrk_core_flutter:
    git:
      url: https://github.com/doleasoft/arrk_core_flutter
      ref: v0.1.0
```

Enable the lints in `analysis_options.yaml`:

```yaml
plugins:
  arrk_lints:
    git:
      url: https://github.com/doleasoft/arrk_core_flutter
      ref: v0.1.0
      path: arrk_lints
    diagnostics:
      avoid_data_models_in_domain: true
      event_bus_publisher_restriction: true
      event_naming_past_tense: true
      no_build_context_in_domain_or_data_or_services: true
      no_change_notifier_outside_vm: true
      no_cross_repo_calls: true
      no_event_bus_in_repo: true
      no_event_fire_in_handler: true
      no_manager_in_features: true
      no_repo_interfaces: true
      no_service_locator_in_features: true
      no_singleton_viewmodel: true
      no_try_catch_in_domain: true
      subscription_cancelled_in_dispose: true
```

## Bootstrap

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServiceLocator.configure((getIt) => getIt.init()); // your generated @InjectableInit
  runApp(const MyApp());
}
```

Hand `ArrkNavigator.mainNavigatorKey` to your `GoRouter(navigatorKey:)` and your `ArrkExtrasCodec` subclass to `GoRouter(extraCodec:)`. Register a `MessageDisplayHandler` implementation in DI — `ArrkViewModel` resolves it there.

## Barrels

One import per layer; `arrk_core_flutter.dart` is the umbrella.

| Barrel | Holds |
|---|---|
| `viewmodel.dart` | `ArrkViewModel`, `VmState`, `ArrkPaginatedDataViewModel`, `MessageDisplayHandler` |
| `view.dart` | `ArrkView`, `ArrkViewBuilder`, `ArrkViewSelector` |
| `data.dart` | `ArrkRepository` (guards), `CachedStream`, `Clock`, typed exceptions |
| `responses.dart` | `Failure` hierarchy, `DataResponse`, `StatusResponse` |
| `events.dart` | `ArrkEvent`, `ArrkEventBus`, session events |
| `navigation.dart` | `ArrkNavigator`, `ArrkRoute`, `ArrkExtrasCodec`, `DeepLinkRoute` |
| `network.dart` | `RestNetworkService`, `DioNetworkService`, `JsonRequest`, `FormDataRequest`, `ApiEnvelope` |
| `services.dart` | `InitializableService`, `ServiceStatus`, service lifecycle exceptions |
| `session.dart` | `ArrkSessionManager`, `ArrkUser` |
| `locator.dart` | `ServiceLocator` |
| `testing.dart` | `FakeClock`, `FakeArrkEventBus`, `NoopMessageHandler` — test code only, not in the umbrella |

## The shape in one paragraph

Views render, VMs hold, usecases decide, repos carry, services wrap. `ArrkView` hosts an `ArrkViewModel` (factory-scoped, screen glue only). Repos are concrete classes extending `ArrkRepository`; their `@protected` guards convert typed exceptions to `Failure`s so everything above the data layer consumes `DataResponse`/`StatusResponse` — no try/catch in domain. Cached state lives in `CachedStream`s composed by repos; one-shot endpoints go straight through the guards. Cross-feature signals are past-tense `ArrkEvent`s fired by usecases and the session manager only. The lints enforce all of it.

## Example

[example/](example/) is a minimal two-screen app exercising the public API end to end: one feature with a usecase, a dto-carried flow, a concrete repo, DI bootstrap, and the lints active. Run it with `flutter run` from `example/`.

## Development

```
flutter analyze          # strict; must be clean
flutter test             # unit tests
cd arrk_lints && dart test   # lint rule fixtures
```

Versioning is semver; see [CHANGELOG.md](CHANGELOG.md). Products pin a tag, never a branch.
