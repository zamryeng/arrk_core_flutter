// OK: guards live in the data layer — try/catch here is exactly right. The
// repo catches at the boundary and returns a response value to the domain.
class AlphaGuardedFetcher {
  String fetch() {
    try {
      return ''.trim();
    } catch (_) {
      return '';
    }
  }
}
