import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'lint_paths.dart';

/// Capabilities (`domain/use_cases/`) are stateless: their only fields are
/// injected dependencies. Flags, in any class there:
/// - a field that is not `final`;
/// - a `final` field with an initializer (`final _cache = <String, X>{}`);
/// - a `late` field.
///
/// Allowed: `static const` fields, and `final` fields set from a
/// constructor parameter.
class CapabilityStateless extends AnalysisRule {
  CapabilityStateless()
    : super(
        name: _name,
        description:
            'Capabilities hold no state. Fields are final and come from the '
            'constructor.',
      );

  static const _name = 'capability_stateless';

  static const _code = LintCode(
    _name,
    "Capability field '{0}' holds state.",
    correctionMessage:
        'Make it a final field set from a constructor parameter, or a '
        'static const. State belongs in a repo (or the flow Dto).',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!isInUseCases(context.unitPath)) return;
    registry.addFieldDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (node.parent?.parent is! ClassDeclaration) return;
    final fields = node.fields;
    if (node.isStatic && fields.isConst) return;
    for (final variable in fields.variables) {
      final holdsState = !fields.isFinal || fields.isLate || variable.initializer != null;
      if (holdsState) {
        rule.reportAtToken(variable.name, arguments: [variable.name.lexeme]);
      }
    }
  }
}
