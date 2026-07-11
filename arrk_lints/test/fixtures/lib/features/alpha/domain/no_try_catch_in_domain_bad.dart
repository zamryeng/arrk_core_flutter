class AlphaGuard {
  String run() {
    // expect_lint: no_try_catch_in_domain
    try {
      return ''.trim();
    } catch (_) {
      return '';
    }
  }

  void runAgain() {
    // expect_lint: no_try_catch_in_domain (try/finally counts too)
    try {
      ''.trim();
    } finally {
      ''.trim();
    }
  }
}
