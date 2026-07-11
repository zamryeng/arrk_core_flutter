import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'lint_paths.dart';

/// Repos (`lib/features/*/data/`) must not reference `ArrkEventBus` at all —
/// not to fire, not to subscribe. Events are a domain concern; the data
/// layer sits below it and stays swappable.
class NoEventBusInRepo extends AnalysisRule {
  NoEventBusInRepo()
    : super(
        name: _name,
        description:
            'The data layer must not know about ArrkEventBus. Events are a '
            'domain concern handled by UseCases and ViewModels.',
      );

  static const _name = 'no_event_bus_in_repo';

  static const _code = LintCode(
    _name,
    'ArrkEventBus referenced inside the data layer.',
    correctionMessage:
        'Remove the event-bus dependency from the repo. Let a UseCase or VM '
        'fire/subscribe; the repo only records data.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!isInFeatureData(context.unitPath)) return;
    registry.addNamedType(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitNamedType(NamedType node) {
    if (node.name.lexeme == 'ArrkEventBus') {
      rule.reportAtNode(node);
    }
  }
}
