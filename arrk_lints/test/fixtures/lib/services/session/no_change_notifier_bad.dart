import '../../_stubs.dart';

// expect_lint: no_change_notifier_outside_vm
// The old session-manager carve-out is gone: the session is a repo stream.
class ArrkSessionManager extends ChangeNotifier {}
