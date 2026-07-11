import '../../../../_stubs.dart';

// OK: route-builder files under ui/.navigation/ are exempt — this is where
// views get their `model:` constructed via the locator.
Object alphaRoute() => View(model: ServiceLocator.get<Object>());

class AlphaRouteVm extends ArrkViewModel {
  void hydrate() {
    // Even a VM method body is exempt inside ui/.navigation/ — the whole
    // route-builder file is sanctioned.
    ServiceLocator.get<String>();
  }
}
