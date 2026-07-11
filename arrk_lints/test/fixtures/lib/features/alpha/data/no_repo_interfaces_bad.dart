// The repo interface/impl split is banned: a repo has exactly one
// implementation, so the interface is speculative indirection.

// expect_lint: no_repo_interfaces (abstract *Repository under lib/features/)
abstract class PaymentsRepository {}

// expect_lint: no_repo_interfaces (abstract *Repo under lib/features/)
abstract class TokensRepo {}

// expect_lint: no_repo_interfaces (*RepositoryImpl — banned anywhere)
class PaymentsRepositoryImpl implements PaymentsRepository {}

// expect_lint: no_repo_interfaces (*RepoImpl — banned anywhere)
class TokensRepoImpl {}
