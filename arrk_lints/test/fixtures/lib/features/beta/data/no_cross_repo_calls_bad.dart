import '../../../_stubs.dart';

class OtherRepo {}

// A repo (extends ArrkRepository) must not reference another *Repo/*Repository
// type — in field types, constructor-parameter types, or member bodies.
class BetaSyncRepo extends ArrkRepository {
  // expect_lint: no_cross_repo_calls (constructor-parameter type)
  BetaSyncRepo(OtherRepo seed) : _other = seed;

  // expect_lint: no_cross_repo_calls (field type)
  OtherRepo? _other;

  void refresh() {
    // expect_lint: no_cross_repo_calls (reference in a member body)
    _other = OtherRepo();
  }
}
