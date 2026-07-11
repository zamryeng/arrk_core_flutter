import '../../../_stubs.dart';

// expect_lint: no_change_notifier_outside_vm (direct)
class DirectNotifier extends ChangeNotifier {}

// expect_lint: no_change_notifier_outside_vm (transitive)
// `CustomBaseNotifier` extends ChangeNotifier; a non-transitive check would
// miss this.
class IndirectNotifier extends CustomBaseNotifier {}
