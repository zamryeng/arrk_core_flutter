// OK: a repo that records data without any ArrkEventBus dependency.
class CleanRepo {
  CleanRepo(this._endpoint);
  final String _endpoint;

  String fetch() => _endpoint;
}
