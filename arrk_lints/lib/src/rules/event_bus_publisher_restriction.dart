import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'ast_helpers.dart';
import 'lint_paths.dart';

/// Only capabilities (`domain/use_cases/`) may publish. Nothing else calls
/// `fire` on an `ArrkEventBus` or `EventPublisher`.
class EventBusPublisherRestriction extends AnalysisRule {
  EventBusPublisherRestriction()
    : super(
        name: _name,
        description:
            'fire(...) on ArrkEventBus / EventPublisher is restricted to '
            'capabilities (domain/use_cases/). Capabilities publish after '
            'the action succeeds; nothing else authors events.',
      );

  static const _name = 'event_bus_publisher_restriction';

  static const _code = LintCode(
    _name,
    'fire(...) outside a capability (domain/use_cases/).',
    correctionMessage:
        'Publish events only from a capability in domain/use_cases/, after '
        'the action succeeds. State changes are not events: put state in a '
        'repo and expose a stream.',
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
    if (isInUseCases(path)) return;
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'fire') return;
    if (!typeIsOrExtends(node.realTarget?.staticType, publisherTypes)) return;
    rule.reportAtNode(node.methodName);
  }
}
