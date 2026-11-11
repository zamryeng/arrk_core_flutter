# arrk_core_flutter

Arrk's Flutter core. The base classes and plumbing every arrk Flutter product consumes — view models, views, repositories, response types, events, navigation, network, service lifecycle, session, and DI wiring — plus `arrk_lints/`, the analyzer plugin that enforces the architecture statically.

Products consume this package; they never own copies of it. The law for how each type is used lives in the arrk corpus (`doctrine/flutter/`), not here — this README covers the mechanics.

## Install

Depend on this repo through a git dependency pinned to a tag. Products pin a tag, never a branch.

```yaml
# pubspec.yaml
dependencies:
  arrk_core_flutter:
    git:
      url: <arrk_core_flutter git URL>
      ref: v0.1.2
```

Enable the lints in `analysis_options.yaml`, from the same repo and tag:

```yaml
plugins:
  arrk_lints:
    git:
      url: <arrk_core_flutter git URL>
      ref: v0.1.2
      path: arrk_lints
    diagnostics:
      avoid_data_models_in_domain: true
      capability_stateless: true
      event_bus_publisher_restriction: true
      event_naming_past_tense: true
      event_subscribe_restriction: true
      message_stream_restriction: true
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
      vm_uses_capabilities_only: true
```

Requires Dart `^3.13.7` and Flutter `>=3.47.8`. arrk starts each dependency range at the latest release; products move up to arrk's versions.

## Bootstrap

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServiceLocator.configure((getIt) => getIt.init()); // your generated @InjectableInit
  await ServiceLocator.get<ArrkSessionRepo>().open();
  ServiceLocator.get<ToastMessageHandler>().start(); // your ArrkMessageHandler subclass
  ServiceLocator.get<AppReactions>().start(); // your ArrkReactions subclass
  runApp(const MyApp());
}
```

Hand `ArrkNavigator.mainNavigatorKey` to your `GoRouter(navigatorKey:)` and your `ArrkExtrasCodec` subclass to `GoRouter(extraCodec:)`. Register one `ArrkEventBus` as itself, `EventPublisher` and `EventStream`, and one `ArrkMessageChannel` as itself, `MessageSink` and `MessageStream`. Every `ArrkViewModel` takes the `MessageSink`. See [docs/01-getting-started.md](docs/01-getting-started.md).

## Barrels

One import per layer; `arrk_core_flutter.dart` is the umbrella.

| Barrel | Holds |
|---|---|
| `viewmodel.dart` | `ArrkViewModel`, `VmState`, `ArrkPaginatedDataViewModel`, `MessageSink`, `UserMessage`, `UserMessageKind` |
| `view.dart` | `ArrkView`, `ArrkViewBuilder`, `ArrkViewSelector`, `MessageStream`, `ArrkMessageChannel`, `ArrkMessageHandler` |
| `data.dart` | `ArrkRepository` (guards), `CachedStream`, `Clock`, typed exceptions |
| `responses.dart` | `Failure` hierarchy (each with a `code`), `ArrkFailureCodes`, `DataResponse`, `StatusResponse` |
| `events.dart` | `ArrkEvent`, `ArrkEventBus`, `EventPublisher`, `EventStream`, `ArrkReactions` |
| `navigation.dart` | `ArrkNavigator`, `ArrkRoute`, `ArrkExtrasCodec`, `DeepLinkRoute` |
| `network.dart` | `RestNetworkService`, `DioNetworkService`, `RequestHeadersProvider`, `JsonRequest`, `FormDataRequest`, `ApiEnvelope` |
| `services.dart` | `InitializableService`, `ServiceStatus`, service lifecycle exceptions |
| `session.dart` | `ArrkSessionRepo`, `ArrkSession`, `ArrkUser` |
| `locator.dart` | `ServiceLocator` |
| `testing.dart` | `FakeClock`, `FakeArrkEventBus`, `FakeMessageSink` — test code only, not in the umbrella |

## The shape in one paragraph

Views render and navigate, VMs hold screen state, capabilities decide, repos own state, services wrap plumbing. `ArrkView` hosts an `ArrkViewModel` (factory-scoped, screen glue only): it calls capabilities only — never repos, services or the event bus — and never navigates; it returns what the view needs to decide where to go. It never calls UI code either: it pushes `UserMessage`s onto a `MessageSink`, and the app's one `ArrkMessageHandler` draws them on the root overlay, merging duplicates, even after the screen that pushed them has closed. A capability (use case) is one class for one named objective, with named methods (no `call()`); it is stateless, may call other capabilities (no loops), and is the only thing that publishes events, after its action succeeds. Every value has one owner: derive it with a getter if you can; a repo owns it if two screens must agree on it or it is true on the server or saved on the device; a Draft owns a flow that spans screens; otherwise the VM owns it. Repos are concrete classes extending `ArrkRepository`; their `@protected` guards convert typed exceptions to `Failure`s so everything above the data layer consumes `DataResponse`/`StatusResponse` — no try/catch in domain. Cached state lives in `CachedStream`s composed by repos; a screen that must show a failed load calls `refresh()` and handles the response. State is not an event: the session, locale, country and balances live in repos and move as streams (`ArrkSessionRepo`). An event is a past-tense fact (`OrderPlaced`), published only when a different feature reacts — within one objective, call the other capability directly. Each product has one `ArrkReactions` class, the only subscriber, which maps each event to capability calls in order and never publishes. Services hold technical state (tokens, connections, request headers) and never app state; only repos read them. The lints enforce it.

## Example

[example/](example/) is a minimal two-screen app exercising the public API end to end: a greeting feature with a capability that publishes, a dto-carried flow, views that navigate on what their VMs return, an activity feature fed by the app's one reactions class, the session as a repo stream, DI bootstrap, and the lints active. Run it with `flutter run` from `example/`.

## Development

```
flutter analyze              # strict; must be clean
flutter test                 # unit tests
cd arrk_lints && dart test   # lint rule fixtures and the baseline gate
arrk_lints/run.sh example    # the lints over the example; must be clean
```

Versioning is semver; see [CHANGELOG.md](CHANGELOG.md). Products pin a tag, never a branch.
