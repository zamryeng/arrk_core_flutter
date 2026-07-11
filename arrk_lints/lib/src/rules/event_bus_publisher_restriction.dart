import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'ast_helpers.dart';
import 'lint_paths.dart';

/// Only UseCases (`domain/use_cases/`) and the session manager may publish on
/// the `ArrkEventBus`. VMs and repos must not call `fire`.
class EventBusPublisherRestriction extends AnalysisRule {
  EventBusPublisherRestriction()
    : super(
        name: _name,
        description:
            'ArrkEventBus.fire(...) is restricted to UseCases and the '
            'session manager. VMs and repos record/consume, they do not '
            'author domain facts.',
      );

  static const _name = 'event_bus_publisher_restriction';

  static const _code = LintCode(
    _name,
    'ArrkEventBus.fire(...) outside a UseCase or the session manager.',
    correctionMessage:
        'Publish events only from domain/use_cases/ or the session_manager '
        'service. VMs subscribe; repos stay below the domain.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final path = context.unitPath;
    if (isInUseCases(path) || isInSessionManager(path)) return;
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'fire') return;
    if (staticTypeName(node.realTarget) != 'ArrkEventBus') return;
    rule.reportAtNode(node.methodName);
  }
}
