// expect_lint: vm_uses_capabilities_only (data-layer import)
import '../data/alpha_cache_repo.dart';
// expect_lint: vm_uses_capabilities_only (service import)
import '../../../services/analytics/analytics_service.dart';
import '../../../_stubs.dart';

class ReachingVm extends ArrkViewModel {
  ReachingVm(
    this._repo,
    // expect_lint: vm_uses_capabilities_only (ctor parameter: event bus half)
    EventStream events,
  ) : _events = events;

  // expect_lint: vm_uses_capabilities_only (field: repository)
  final AlphaCacheRepo _repo;
  // expect_lint: vm_uses_capabilities_only (field: event bus half)
  final EventStream _events;
  // expect_lint: vm_uses_capabilities_only (field: bus)
  ArrkEventBus? _bus;
  final AnalyticsService _analytics = AnalyticsService();
}
