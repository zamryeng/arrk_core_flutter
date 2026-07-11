import '../../../_stubs.dart';

// A ViewModel's dependencies arrive at construction — mid-method locator
// lookups inside an ArrkViewModel subclass are banned wherever the VM lives
// (VMs live under ui/).
class AlphaVm extends ArrkViewModel {
  void load() {
    // expect_lint: no_service_locator_in_features (VM method body)
    ServiceLocator.get<String>();
    // expect_lint: no_service_locator_in_features (VM method body, GetIt)
    GetIt.I<int>();
  }
}

// Transitive: a VM reaching ArrkViewModel through an intermediate base is
// still a VM.
class AlphaPagedVm extends PaginatedDataViewModel {
  void refresh() {
    // expect_lint: no_service_locator_in_features (transitive VM)
    GetIt.instance<int>();
  }
}
