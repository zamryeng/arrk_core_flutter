# arrk_lints

Native analyzer-plugin lint rules that enforce the arrk Flutter architecture
contract in consuming products (code under `lib/features/<feature>/{data,domain,ui}/`
and `lib/services/`). Built on `analysis_server_plugin` (Dart 3.10+), so the
rules run inside `dart analyze`, `flutter analyze`, and the IDE.

## The rules

| Rule | Fires on |
|------|----------|
| `avoid_data_models_in_domain` | Importing `data/{models,sources,mappers}` from outside that feature's `data/`. Exempt: `lib/services/` (data-access backends map at the boundary). |
| `event_bus_publisher_restriction` | `ArrkEventBus.fire` outside `domain/use_cases/` or the session manager |
| `event_naming_past_tense` | Command-shaped `ArrkEvent` subclass names (`RefreshBalance`; facts only: `BalanceRefreshed`) |
| `no_build_context_in_domain_or_data_or_services` | `BuildContext` as a parameter, field, or getter return type in `domain/`, `data/`, `services/` |
| `no_change_notifier_outside_vm` | `extends ChangeNotifier` outside `ArrkViewModel` / `ArrkSessionManager` (Flutter controller types exempt) |
| `no_cross_repo_calls` | An `ArrkRepository` subclass referencing another `*Repo`/`*Repository` type — repos never call repos; an operation spanning two repos is a usecase |
| `no_event_bus_in_repo` | Any `ArrkEventBus` reference in a feature's `data/` |
| `no_event_fire_in_handler` | Firing an event inside a `.listen(...)` handler |
| `no_manager_in_features` | `*Manager` class names under `lib/features/` (reserved for `lib/services/`) |
| `no_repo_interfaces` | Abstract `*Repo`/`*Repository` under `lib/features/`, and any `*RepoImpl`/`*RepositoryImpl` anywhere — repos are concrete classes; delete the interface, keep one concrete repo |
| `no_service_locator_in_features` | `ServiceLocator.get` / `GetIt` lookups in feature `domain/`, or inside `ArrkViewModel` method bodies anywhere. Exempt: constructor-fallback initializers, `ui/.navigation/` route builders, non-VM UI code constructing `model:` |
| `no_singleton_viewmodel` | `@singleton`/`@lazySingleton` on an `ArrkViewModel` |
| `no_try_catch_in_domain` | Any `try` statement in a feature's `domain/` — domain consumes `DataResponse`/`StatusResponse`; guards live in the data layer only |
| `subscription_cancelled_in_dispose` | `StreamSubscription` VM fields not cancelled in `dispose()` |

## Enabling in a product

Add the plugin to the product's `analysis_options.yaml`:

```yaml
plugins:
  arrk_lints:
    git:
      url: https://github.com/doleasoft/arrk_core_flutter
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
   surface *none* of these lints; pass files explicitly and they show up under
   both `dart analyze <file>` and `flutter analyze <file>`. `run.sh` enumerates
   every Dart file under `lib/` (tracked + untracked-not-ignored) and passes
   them explicitly. The IDE loads the plugin and surfaces the lints inline.
2. **`// ignore` / `// ignore_for_file` do not suppress plugin lints yet.**

## Running

```bash
arrk_lints/run.sh              # analyze the current directory's lib/
arrk_lints/run.sh path/to/app  # analyze another project
```

## Testing

Golden fixtures live under `test/fixtures/lib/`, one positive (`*_bad.dart`,
must flag exactly its `// expect_lint: <rule>` markers) and one negative
(`*_ok.dart`, must stay clean) per rule, at paths that satisfy each rule's
scoping. `test/fixtures/analysis_options.yaml` enables the plugin for that
tree; `test/fixtures/lib/_stubs.dart` provides minimal stand-ins for the core
types the fixtures reference.

```bash
dart pub get
dart test
```

## Developing a rule

Rules live in `lib/src/rules/`, extend `AnalysisRule`, and are registered in
`lib/main.dart`. After editing the `plugins:` block in a product's
`analysis_options.yaml`, restart the Dart Analysis Server to pick up changes.
