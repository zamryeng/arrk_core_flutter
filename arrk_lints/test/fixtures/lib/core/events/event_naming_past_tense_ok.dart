import '../../_stubs.dart';

// OK: past-tense fact names.
class BalanceRefreshed extends ArrkEvent {}

class TransactionSent extends ArrkEvent {}

// OK: `Updated` ends past-tense — the prefix guard must not match `Update`.
class ProfileUpdated extends ArrkEvent {}
