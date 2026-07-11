import '../../../_stubs.dart';

class LocatorUser {
  void run() {
    // expect_lint: no_service_locator_in_features
    ServiceLocator.get<String>();
    // expect_lint: no_service_locator_in_features
    GetIt.instance<int>();
    // expect_lint: no_service_locator_in_features
    GetIt.I<int>();
  }
}
