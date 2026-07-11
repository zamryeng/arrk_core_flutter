
// OK: dependencies come through the constructor, not a service-locator lookup.
class InjectedUser {
  InjectedUser(this._dependency);
  final String _dependency;

  void run() {
    _dependency.length;
  }
}
