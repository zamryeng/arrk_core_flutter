import '../../../_stubs.dart';

// OK: cancelled directly in dispose().
class DirectCancelVm extends ArrkViewModel {
  StreamSubscription? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// OK (false-positive case): dispose() delegates to a helper that performs the
// cancel. Substring matching on the dispose body alone would have wrongly
// flagged `_sub` as un-cancelled.
class HelperDelegatedVm extends ArrkViewModel {
  StreamSubscription? _sub;

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  void _cleanup() {
    _sub?.cancel();
  }
}

// OK: `this.`-qualified cancel resolves to the field too.
class ThisQualifiedVm extends ArrkViewModel {
  StreamSubscription? _sub;

  @override
  void dispose() {
    this._sub?.cancel();
    super.dispose();
  }
}
