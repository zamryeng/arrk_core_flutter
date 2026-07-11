---
title: Getting started
updated_at: 2026-07-11
---

[← Back to docs index](00-index.md)

# Getting started

## Install

Pin a tag via git dependency (see the [README](../README.md) for the exact blocks — dependency and lints plugin). Products pin tags, never branches: a moving ref makes builds unreproducible.

## Bootstrap order

`main()` wires four seams, in this order:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. DI — hand your generated @InjectableInit entry point to the seam.
  await ServiceLocator.configure((getIt) => getIt.init());

  // 2. Session — open before anything reads requestHeaders.
  await ServiceLocator.get<MySessionManager>().open();

  runApp(const MyApp());
}
```

3. **Router.** Your `GoRouter` takes `navigatorKey: ArrkNavigator.mainNavigatorKey` (so `ArrkNavigator.main` works anywhere) and `extraCodec: const MyExtrasCodec()` (your `ArrkExtrasCodec` subclass, listing every Dto/args type that crosses a route).

4. **Messages.** Register a `MessageDisplayHandler` implementation in DI — every `ArrkViewModel` constructed without an explicit handler resolves it from there. Forgetting this fails fast at first VM construction.

## What a product implements

| Seam | You provide |
|---|---|
| `ArrkSessionManager` | the concrete session: storage, identity, `requestHeaders` composition |
| `ArrkExtrasCodec.types` | one `ArrkExtraType` per navigable Dto/args type |
| `MessageDisplayHandler` | toast/banner rendering |
| `DioNetworkService` registration | one per API host, fed base URL + timeouts + your session manager |
| Deep links | `DeepLinkRoute` entries aggregated into your route table |

## Platform note

Every barrel compiles on mobile, desktop, and web. The one runtime restriction: `FormDataRequest` file upload is io-only — on web its `File` stand-in throws `UnsupportedError` when used.

---

[← Back to docs index](00-index.md)
