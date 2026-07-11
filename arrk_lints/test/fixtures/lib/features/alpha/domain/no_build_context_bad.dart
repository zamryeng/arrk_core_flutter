import '../../../_stubs.dart';

class ContextSmuggler {
  // expect_lint: no_build_context_in_domain_or_data_or_services (field)
  BuildContext? _context;

  // expect_lint: no_build_context_in_domain_or_data_or_services (parameter)
  void doThing(BuildContext context) {}

  // expect_lint: no_build_context_in_domain_or_data_or_services (getter)
  BuildContext get context => _context!;
}
