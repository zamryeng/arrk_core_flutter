import '../../../_stubs.dart';

// expect_lint: subscription_cancelled_in_dispose
// `_sub` is never cancelled anywhere reachable from dispose().
class UncancelledVm extends ArrkViewModel {
  StreamSubscription? _sub;

  @override
  void dispose() {
    super.dispose();
  }
}

// expect_lint: subscription_cancelled_in_dispose (false-negative case)
// An unrelated `_other.cancel()` must NOT satisfy the different field `_sub`.
// Substring matching on `.cancel(` would have wrongly cleared `_sub`.
class UnrelatedCancelVm extends ArrkViewModel {
  StreamSubscription? _sub;
  StreamSubscription? _other;

  @override
  void dispose() {
    _other?.cancel();
    super.dispose();
  }
}
