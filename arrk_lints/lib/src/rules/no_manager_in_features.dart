import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'lint_paths.dart';

/// Bans `*Manager` class names inside `lib/features/`.
///
/// The architecture deletes the manager pattern from features: state +
/// orchestration split into stateful repos + stateless UseCases + factory
/// VMs. The `Manager` suffix is reserved for system-level state holders in
/// `lib/services/` (e.g. `ArrkSessionManager`).
class NoManagerInFeatures extends AnalysisRule {
  NoManagerInFeatures()
    : super(
        name: _name,
        description:
            'Manager classes are banned in lib/features/. Split state and '
            'orchestration into repos + UseCases + factory ViewModels.',
      );

  static const _name = 'no_manager_in_features';

  static const _code = LintCode(
    _name,
    "'{0}' uses the banned Manager pattern inside lib/features/.",
    correctionMessage:
        'Split it into a stateful repo (CachedStream), stateless UseCases, '
        'and factory-scoped ViewModels. The Manager suffix is reserved for '
        'system-level holders in lib/services/.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!isInFeatures(context.unitPath)) return;
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final nameToken = node.namePart.typeName;
    final name = nameToken.lexeme;
    if (name.endsWith('Manager')) {
      rule.reportAtToken(nameToken, arguments: [name]);
    }
  }
}
