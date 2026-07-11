import 'package:analyzer/analysis_rule/rule_context.dart';

/// Path helpers shared by the architecture rules.
///
/// The analyzer gives us the absolute file path of the unit under analysis.
/// The architecture's bans are scoped by where a file lives (feature layer,
/// services, etc.), so every rule needs to ask questions like "is this file
/// inside a feature's `data/` folder?".
///
/// We match on normalized `/lib/...` relative segments so the checks work
/// regardless of where the repo is checked out.
extension RuleContextPaths on RuleContext {
  /// The unit's absolute file path, with backslashes normalized to forward
  /// slashes so the segment checks below are platform-independent.
  String get unitPath =>
      definingUnit.unit.declaredFragment?.source.fullName.replaceAll(r'\', '/') ?? '';
}

/// The portion of [path] starting at `lib/`, or the whole path if no `lib/`
/// segment is present.
String libRelative(String path) {
  final index = path.indexOf('/lib/');
  if (index == -1) return path;
  return path.substring(index + 1); // keep the leading "lib/"
}

/// Whether [path] is inside any feature's `data/` folder
/// (`lib/features/<x>/.../data/...`).
bool isInFeatureData(String path) {
  final rel = libRelative(path);
  return rel.startsWith('lib/features/') && rel.contains('/data/');
}

/// Whether [path] is inside a feature's `domain/` folder.
bool isInFeatureDomain(String path) {
  final rel = libRelative(path);
  if (!rel.startsWith('lib/features/')) return false;
  return rel.contains('/domain/');
}

/// Whether [path] is inside a feature's `domain/` or `data/` folder
/// (the context-free layers — `ui/` is allowed to touch `BuildContext`).
bool isInFeatureDomainOrData(String path) {
  final rel = libRelative(path);
  if (!rel.startsWith('lib/features/')) return false;
  return rel.contains('/domain/') || rel.contains('/data/');
}

/// Whether [path] is anywhere under `lib/features/`.
bool isInFeatures(String path) => libRelative(path).startsWith('lib/features/');

/// Whether [path] is anywhere under `lib/services/`.
bool isInServices(String path) => libRelative(path).startsWith('lib/services/');

/// Whether [path] is inside a feature's `domain/use_cases/` folder — the only
/// place (besides the session manager) allowed to publish events.
bool isInUseCases(String path) {
  final rel = libRelative(path);
  return rel.startsWith('lib/features/') && rel.contains('/domain/use_cases/');
}

/// Whether [path] is inside the session manager service folder.
bool isInSessionManager(String path) =>
    libRelative(path).startsWith('lib/services/session_manager/');

/// Whether [path] is a route-builder file under a feature's `ui/.navigation/`
/// folder — the sanctioned place to construct a view's `model:` via the
/// service locator.
bool isInUiNavigation(String path) => path.contains('/ui/.navigation/');
