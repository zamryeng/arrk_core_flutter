import '../../../_stubs.dart';

// OK: non-VM UI code may reach the service locator — constructing a view's
// `model:` argument in a widget file is exactly the sanctioned use. Only
// feature domain/ and ArrkViewModel method bodies are banned.
class LocatorView {
  void run() {
    ServiceLocator.get<String>();
    GetIt.instance<int>();
    GetIt.I<int>();
  }

  Object build() => View(model: ServiceLocator.get<Object>());
}
