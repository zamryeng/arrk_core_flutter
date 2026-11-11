# arrk_lints

Native analyzer-plugin lint rules that enforce the arrk Flutter architecture
contract in consuming products (code under `lib/features/<feature>/{data,domain,ui}/`
and `lib/services/`). Built on `analysis_server_plugin` (Dart 3.10+), so the
rules run inside `dart analyze`, `flutter analyze`, and the IDE.

## The rules

| Rule | Fires on |
|------|----------|
| `avoid_data_models_in_domain` | Importing `data/{models,sources,mappers}` from outside that feature's `data/`. Exempt: `lib/services/` (data-access backends map at the boundary). |
| `capability_stateless` | In `domain/use_cases/`: a field that is not `final`, a `final` field with an initializer, or a `late` field. Allowed: `static const`, and `final` fields set from a constructor parameter |
| `event_bus_publisher_restriction` | `fire` on an `ArrkEventBus` or `EventPublisher` anywhere outside `domain/use_cases/` |
| `event_naming_past_tense` | Command-shaped `ArrkEvent` subclass names (`RefreshBalance`; facts only: `BalanceRefreshed`) |
| `event_subscribe_restriction` | `on<...>()` or `all` on an `ArrkEventBus` or `EventStream`, or a field typed `EventStream`, outside a class that extends `ArrkReactions` |
| `message_stream_restriction` | Any reference to `MessageStream` or `ArrkMessageChannel` outside a class that extends `ArrkMessageHandler` and outside DI registration and the composition root (`lib/di/`, `lib/app/`, or a class annotated `@module`) |
| `no_build_context_in_domain_or_data_or_services` | `BuildContext` as a parameter, field, or getter return type in `domain/`, `data/`, `services/` |
| `no_change_notifier_outside_vm` | `extends ChangeNotifier` outside `ArrkViewModel` (Flutter controller types exempt) |
| `no_cross_repo_calls` | An `ArrkRepository` subclass referencing another `*Repo`/`*Repository` type — repos never call repos; an operation spanning two repos is a usecase |
| `no_event_bus_in_repo` | Any `ArrkEventBus`, `EventPublisher` or `EventStream` reference in a feature's `data/` |
| `no_event_fire_in_handler` | Firing an event inside a `.listen(...)` handler, or any `EventPublisher` / `ArrkEventBus` reference inside a class that extends `ArrkReactions` |
| `no_manager_in_features` | `*Manager` class names under `lib/features/` (reserved for `lib/services/`) |
| `no_repo_interfaces` | Abstract `*Repo`/`*Repository` under `lib/features/`, and any `*RepoImpl`/`*RepositoryImpl` anywhere — repos are concrete classes; delete the interface, keep one concrete repo |
| `no_service_locator_in_features` | `ServiceLocator.get` / `GetIt` lookups in feature `domain/`, or inside `ArrkViewModel` method bodies anywhere. Exempt: constructor-fallback initializers, `ui/.navigation/` route builders, non-VM UI code constructing `model:` |
| `no_singleton_viewmodel` | `@singleton`/`@lazySingleton` on an `ArrkViewModel` |
| `no_try_catch_in_domain` | Any `try` statement in a feature's `domain/` — domain consumes `DataResponse`/`StatusResponse`; guards live in the data layer only |
| `subscription_cancelled_in_dispose` | `StreamSubscription` VM fields not cancelled in `dispose()` |
| `vm_uses_capabilities_only` | In a file with an `ArrkViewModel` subclass: importing a product file under `lib/features/*/data/` or `lib/services/`; in the VM, a field or constructor parameter typed `ArrkEventBus` / `EventPublisher` / `EventStream` or `MessageStream` / `ArrkMessageChannel` / `ArrkMessageHandler`, or whose type extends `ArrkRepository`. A VM may only hold `MessageSink`. `package:arrk_core_flutter/...` imports are allowed |

## Enabling in a product

Add the plugin to the product's `analysis_options.yaml`:

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

The example app inside this repo uses a path source instead:

```yaml
plugins:
  arrk_lints:
    path: ../arrk_lints
    diagnostics:
      # ... same entries
```

## Toolchain caveats

1. **Plugin diagnostics only appear for explicitly-listed file arguments, not
   directory-mode analysis.** `dart analyze <dir>` and a bare `flutter analyze`
   surface *none* of these lints. Pass files explicitly to **`dart analyze`**
   and they show up. `flutter analyze <file>` does **not** surface them
   (verified on Flutter 3.47.9 / Dart 3.13.7), so a gate built on it passes
   violating code silently. `run.sh` enumerates every Dart file under `lib/`
   (tracked + untracked-not-ignored, skipping tracked files deleted from the
   working tree), passes them to `dart analyze`, and fails if no analysis ran.
   Products should gate on `run.sh`, not on a wrapper of their own. The IDE
   loads the plugin and surfaces the lints inline.
2. **`// ignore` / `// ignore_for_file` do not suppress plugin lints yet.** Use the baseline (below) for violations you can't fix yet.

## Running

```bash
arrk_lints/run.sh              # gate the current directory's lib/
arrk_lints/run.sh path/to/app  # gate another project
```

`run.sh` needs `python3`. It fails on analysis errors (unresolved sources make plugin diagnostics unreliable) and on any arrk violation that is not in the project's baseline. Other analyzer diagnostics are `flutter analyze`'s job.

## Baseline

An app that adopts arrk partway through its life can't fix every violation in one change. Grandfather them:

```bash
arrk_lints/run.sh --update    # write arrk_baseline.txt at the project root; commit it
arrk_lints/run.sh             # fail only on violations not in the baseline
arrk_lints/run.sh --report    # violation count per rule
```

`arrk_baseline.txt` holds one `rule|file|message` line per violation, without line numbers, so it survives edits. Two identical violations in one file are two lines. A baselined violation that disappears is reported as fixed, with a reminder to run `--update`; it does not fail the run. With no baseline file, every violation fails. Accept new violations into the baseline only with reviewer sign-off.
