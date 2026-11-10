---
title: Getting started
updated_at: 2026-11-10
---

[← Back to docs index](00-index.md)

# Getting started

## Install

Pin a tag via git dependency (see the [README](../README.md) for the exact blocks — dependency and lints plugin). Products pin tags, never branches: a moving ref makes builds unreproducible.

## Bootstrap order

`main()` wires the seams in this order:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. DI — hand your generated @InjectableInit entry point to the seam.
  await ServiceLocator.configure((getIt) => getIt.init());

  // 2. Session — open before anything sends a request. The session repo
  //    writes the request headers into your RequestHeadersProvider.
  await ServiceLocator.get<ArrkSessionRepo>().open();

  // 3. Messages — start the one message reader before anything can push.
  //    A push with no listener is dropped.
  ServiceLocator.get<ToastMessageHandler>().start();

  // 4. Reactions — start the one event subscriber.
  ServiceLocator.get<AppReactions>().start();

  runApp(const MyApp());
}
```

5. **Router.** Your `GoRouter` takes `navigatorKey: ArrkNavigator.mainNavigatorKey` (so `ArrkNavigator.main` works anywhere) and `extraCodec: const MyExtrasCodec()` (your `ArrkExtrasCodec` subclass, listing every Dto/args type that crosses a route). Views navigate; view models return what the view needs to decide.

6. **Event bus.** Register one `ArrkEventBus` as itself and as both halves. Capabilities take `EventPublisher`; the reactions class takes `EventStream`.

   ```dart
   @module
   abstract class EventsModule {
     @singleton
     ArrkEventBus get eventBus => ArrkEventBus();
     @singleton
     EventPublisher eventPublisher(ArrkEventBus bus) => bus;
     @singleton
     EventStream eventStream(ArrkEventBus bus) => bus;
   }
   ```

7. **Messages.** Register one `ArrkMessageChannel` as itself and as both halves, the same split as the event bus. Every `ArrkViewModel` takes `MessageSink` as a required constructor argument (`MyVm(this._capability, super.messageSink)`) and pushes through `handleError` and `showSuccess` / `showWarning` / `showInfo` — even after it is disposed. Your one `ArrkMessageHandler` subclass takes `MessageStream` and draws each message on the root overlay (not in a `Scaffold`, where a modal sheet can cover it). It shows messages from hidden screens too, and skips a message with the same kind and text as one shown within `dedupeWindow` (2 seconds by default). Tests pass a `FakeMessageSink()`.

   ```dart
   @module
   abstract class MessagesModule {
     @singleton
     ArrkMessageChannel get messageChannel => ArrkMessageChannel();
     @singleton
     MessageSink messageSink(ArrkMessageChannel channel) => channel;
     @singleton
     MessageStream messageStream(ArrkMessageChannel channel) => channel;
   }
   ```

## What a product implements

| Seam | You provide |
|---|---|
| `ArrkSessionRepo` | the concrete session repo (singleton): storage, identity, locale/country, and writing the matching headers into your `RequestHeadersProvider` |
| `RequestHeadersProvider` | a service holding the outgoing-request headers (plumbing only; it never reads a repo) |
| `ArrkReactions` | the one reactions class: an exhaustive `switch` over your sealed event family, calling capabilities |
| `ArrkExtrasCodec.types` | one `ArrkExtraType` per navigable Dto/args type |
| `ArrkMessageHandler` | the one message reader: `show()` draws a toast on the root overlay |
| `DioNetworkService` registration | one per API host, fed base URL + timeouts + your `RequestHeadersProvider` |
| `CachedStream` storage | `readLocal`, `writeLocal` and `clearLocal` per cache (no-ops if you keep nothing on disk); call `clear()` on sign-out |
| Deep links | `DeepLinkRoute` entries aggregated into your route table |

## Adopting the lints in an existing app

An app that adopts arrk partway through its life has many violations at once. Record them in a baseline and gate only on new ones:

```bash
arrk_lints/run.sh --update    # writes arrk_baseline.txt at the project root; commit it
arrk_lints/run.sh             # fails only on violations not in the baseline
arrk_lints/run.sh --report    # violation count per rule
```

Baseline lines are `rule|file|message`, with no line numbers, so they survive edits. A baselined violation that disappears is reported as fixed; run `--update` to drop it.

## Platform note

Every barrel compiles on mobile, desktop, and web. The one runtime restriction: `FormDataRequest` file upload is io-only — on web its `File` stand-in throws `UnsupportedError` when used.

---

[← Back to docs index](00-index.md)
