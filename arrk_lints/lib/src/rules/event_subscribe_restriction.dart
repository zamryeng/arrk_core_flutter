import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'ast_helpers.dart';

/// Only the product's `ArrkReactions` class subscribes. Everywhere else,
/// flags:
/// - `on<...>()` or `all` on an `ArrkEventBus` or `EventStream`;
/// - a field typed `EventStream`.
class EventSubscribeRestriction extends AnalysisRule {
  EventSubscribeRestriction()
    : super(
        name: _name,
        description:
            'Subscribing to events is reserved for the ArrkReactions class. '
            'View models, views, repos and capabilities never subscribe.',
      );

  static const _name = 'event_subscribe_restriction';

  static const _code = LintCode(
    _name,
    'Event subscription outside the ArrkReactions class.',
    correctionMessage:
        'Map the event to a capability call in the product\'s ArrkReactions '
        'class. Screens watch repo state through capabilities instead of '
        'listening to events.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
    registry.addPrefixedIdentifier(this, visitor);
    registry.addPropertyAccess(this, visitor);
    registry.addFieldDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  static const _reactions = {'ArrkReactions'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'on') return;
    if (!typeIsOrExtends(node.realTarget?.staticType, subscriberTypes)) return;
    if (isInsideClassExtending(node, _reactions)) return;
    rule.reportAtNode(node.methodName);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name != 'all') return;
    if (!typeIsOrExtends(node.prefix.staticType, subscriberTypes)) return;
    if (isInsideClassExtending(node, _reactions)) return;
    rule.reportAtNode(node.identifier);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name != 'all') return;
    if (!typeIsOrExtends(node.realTarget.staticType, subscriberTypes)) return;
    if (isInsideClassExtending(node, _reactions)) return;
    rule.reportAtNode(node.propertyName);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    final type = node.fields.type;
    if (type is! NamedType || type.name.lexeme != 'EventStream') return;
    if (isInsideClassExtending(node, _reactions)) return;
    rule.reportAtNode(type);
  }
}
