import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'ast_helpers.dart';

/// Bans `extends ChangeNotifier` outside the `ArrkViewModel` base.
/// Everything else uses streams (repos/services).
class NoChangeNotifierOutsideVm extends AnalysisRule {
  NoChangeNotifierOutsideVm()
    : super(
        name: _name,
        description:
            'ChangeNotifier is reserved for ArrkViewModel. Repos and '
            'services expose streams.',
      );

  static const _name = 'no_change_notifier_outside_vm';

  static const _code = LintCode(
    _name,
    "'{0}' extends ChangeNotifier outside the allowed places.",
    correctionMessage:
        'Extend ArrkViewModel for view state, or expose streams from a repo / '
        'service. ArrkViewModel is the only ChangeNotifier carve-out.',
    severity: DiagnosticSeverity.WARNING,
  );

  /// The carve-out allowed to be a ChangeNotifier (by its own name, or as a
  /// supertype — every `ArrkViewModel` subclass reaches ChangeNotifier
  /// through it and is fine).
  static const _allowedNames = {'ArrkViewModel'};

  /// Flutter framework types that are themselves ChangeNotifiers and are
  /// legitimate to subclass (e.g. a custom `TextEditingController`). Reaching
  /// ChangeNotifier *through* one of these is not the smell this rule targets —
  /// the smell is hand-rolled view/domain state on a bare `ChangeNotifier`.
  static const _frameworkNotifiers = {
    'TextEditingController',
    'ValueNotifier',
    'ScrollController',
    'TabController',
    'AnimationController',
    'PageController',
    'TransformationController',
    'FocusNode',
    'RestorableProperty',
    'PlatformRouteInformationProvider',
    'RouterDelegate',
  };

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // Transitive (like the sibling rules) so a custom `extends SomeBaseNotifier`
    // is caught too, not just `extends ChangeNotifier` directly.
    if (!hasSupertypeNamed(node, const {'ChangeNotifier'})) return;
    final name = node.namePart.typeName.lexeme;
    // The carve-outs themselves are allowed.
    if (NoChangeNotifierOutsideVm._allowedNames.contains(name)) return;
    // Allowed if it reaches ChangeNotifier *through* a project carve-out (every
    // ArrkViewModel subclass) or a legitimate Flutter framework notifier
    // (a custom TextEditingController, etc.).
    if (hasSupertypeNamed(node, NoChangeNotifierOutsideVm._allowedNames)) return;
    if (hasSupertypeNamed(node, NoChangeNotifierOutsideVm._frameworkNotifiers)) {
      return;
    }
    rule.reportAtToken(node.namePart.typeName, arguments: [name]);
  }
}
