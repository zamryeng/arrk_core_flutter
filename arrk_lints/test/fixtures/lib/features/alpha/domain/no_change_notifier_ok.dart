import '../../../_stubs.dart';

// OK: an ArrkViewModel subclass reaches ChangeNotifier only through the
// ArrkViewModel carve-out — that is the sanctioned place for view state.
class FineVm extends ArrkViewModel {}

// OK: subclassing a Flutter framework notifier (a custom TextEditingController)
// is a legitimate pattern, not the hand-rolled-state smell this rule targets.
class AmountController extends TextEditingController {}

// OK: a plain class that does not reach ChangeNotifier at all.
class PlainThing {}
