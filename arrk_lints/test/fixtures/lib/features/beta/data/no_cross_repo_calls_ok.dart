import '../../../_stubs.dart';

// OK: a repo that only touches its own data. Self-references (own name) and
// the ArrkRepository base are exempt.
class CleanSyncRepo extends ArrkRepository {
  CleanSyncRepo(this._endpoint);
  final String _endpoint;

  static CleanSyncRepo fresh() => CleanSyncRepo('');

  void adopt(ArrkRepository base) {
    base.toString();
  }

  String fetch() => _endpoint;
}

// OK: a non-repo coordinator (usecase-shaped) may take two repos — that is
// exactly where multi-repo operations belong.
class SyncAccountsUseCase {
  SyncAccountsUseCase(this._a, this._b);
  final CleanSyncRepo _a;
  final CleanSyncRepo _b;

  void call() {
    _a.fetch();
    _b.fetch();
  }
}
