// Minimal stand-ins for the core/framework types the fixtures reference, so
// the fixtures resolve without pulling in arrk_core_flutter or Flutter. The
// rules key on these names (supertype names, annotation names, type names),
// so the stubs only need to reproduce the shapes the rules look at.

class ArrkViewModel {
  void dispose() {}
}

/// A custom base that itself extends [ArrkViewModel] — used to prove the
/// subscription / singleton rules follow the supertype chain transitively.
class PaginatedDataViewModel extends ArrkViewModel {}

class ChangeNotifier {}

/// A custom base notifier — proves `no_change_notifier_outside_vm` is
/// transitive (`extends CustomBaseNotifier` must still be flagged).
class CustomBaseNotifier extends ChangeNotifier {}

/// Framework-style notifier that is legitimate to subclass.
class TextEditingController extends ChangeNotifier {}

class ArrkEvent {}

class ArrkEventBus {
  void fire(Object event) {}
  Stream<T> on<T>() => Stream<T>();
}

/// Base class for repos — `no_cross_repo_calls` keys on this supertype name.
class ArrkRepository {}

class BuildContext {}

/// A UI dependency used by the constructor-fallback injection fixtures.
class MessageDisplayHandler {}

/// Widget stand-in taking the `model:` argument route builders construct.
class View {
  View({Object? model});
}

const singleton = _Singleton();
const lazySingleton = _LazySingleton();

class _Singleton {
  const _Singleton();
}

class _LazySingleton {
  const _LazySingleton();
}

/// Constructor-call annotation forms (`@Singleton()` / `@LazySingleton()`).
class Singleton {
  const Singleton();
}

class LazySingleton {
  const LazySingleton();
}

class StreamSubscription {
  Future<void> cancel() async {}
}

class Stream<T> {
  StreamSubscription listen(void Function(T event) onData) => StreamSubscription();
}

class ServiceLocator {
  static T get<T>() => throw UnimplementedError();
}

class GetIt {
  static final GetIt instance = GetIt();
  static final GetIt I = GetIt();
  T call<T>() => throw UnimplementedError();
}
