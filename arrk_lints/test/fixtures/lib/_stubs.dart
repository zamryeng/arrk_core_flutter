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

abstract interface class EventPublisher {
  void fire(Object event);
}

abstract interface class EventStream {
  Stream<T> on<T>();
  Stream<ArrkEvent> get all;
}

class ArrkEventBus implements EventPublisher, EventStream {
  @override
  void fire(Object event) {}
  @override
  Stream<T> on<T>() => Stream<T>();
  @override
  Stream<ArrkEvent> get all => Stream<ArrkEvent>();
}

/// The one sanctioned subscriber.
abstract class ArrkReactions<E> {
  ArrkReactions(this.events);
  final EventStream events;
  void start() {}
  Future<void> react(E event);
}

/// Base class for repos — `no_cross_repo_calls` keys on this supertype name.
class ArrkRepository {}

class BuildContext {}

/// The message write side: the one message type a VM may hold.
abstract interface class MessageSink {
  void push(Object message);
}

/// The message read side.
abstract interface class MessageStream {
  Stream<Object> get messages;
}

class ArrkMessageChannel implements MessageSink, MessageStream {
  @override
  void push(Object message) {}
  @override
  Stream<Object> get messages => Stream<Object>();
}

/// The one message reader.
abstract class ArrkMessageHandler {
  ArrkMessageHandler(this.messages);
  final MessageStream messages;
  void show(Object message);
}

/// Widget stand-in taking the `model:` argument route builders construct.
class View {
  View({Object? model});
}

const singleton = _Singleton();
const module = _Module();

class _Module {
  const _Module();
}
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
