import '../../../../_stubs.dart';

class StatefulUseCase {
  StatefulUseCase(this._repo);

  final ArrkRepository _repo;

  // expect_lint: capability_stateless (not final)
  int _calls = 0;
  // expect_lint: capability_stateless (final with an initializer)
  final _cache = <String, int>{};
  // expect_lint: capability_stateless (late)
  late final String _lazy;
  // expect_lint: capability_stateless (static mutable)
  static int counter = 0;
}
