import '../../../_stubs.dart';

// OK: the UI layer is allowed to take a BuildContext — the rule is scoped to
// domain/, data/, and services/ only.
class AlphaView {
  void render(BuildContext context) {}
  BuildContext? stored;
  BuildContext get ctx => stored!;
}
