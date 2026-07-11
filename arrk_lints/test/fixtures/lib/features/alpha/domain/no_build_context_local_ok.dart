import '../../../_stubs.dart';

// OK: a BuildContext used only as a local variable/cast inside a method body is
// out of scope — the rule bans it as a parameter, field, or getter return type,
// not every textual mention.
class LocalContextUser {
  void run(Object raw) {
    final BuildContext ctx = raw as BuildContext;
    ctx.toString();
  }
}
