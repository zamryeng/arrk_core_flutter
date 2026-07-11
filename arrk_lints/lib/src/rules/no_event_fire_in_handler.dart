import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'ast_helpers.dart';

/// Bans firing an event from inside an event-handler closure
/// (`bus.on<T>().listen((e) { bus.fire(...); })`). Handlers consume only —
/// re-publishing creates untraceable signal loops.
class NoEventFireInHandler extends AnalysisRule {
  NoEventFireInHandler()
    : super(
        name: _name,
        description:
            'ArrkEventBus handlers must not fire events. Re-publishing inside '
            'a listener creates cycles.',
      );

  static const _name = 'no_event_fire_in_handler';

  static const _code = LintCode(
    _name,
    'ArrkEventBus.fire(...) inside an event-handler closure.',
    correctionMessage:
        'Handlers consume only. Move the follow-up emit to the original '
        'publisher (the UseCase that caused the first event).',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
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
    if (_isInsideListenClosure(node)) {
      rule.reportAtNode(node.methodName);
    }
  }

  /// Walks ancestors looking for a closure that is an argument to a `.listen`
  /// invocation — i.e. an event/stream handler body.
  bool _isInsideListenClosure(AstNode node) {
    for (AstNode? current = node; current != null; current = current.parent) {
      if (current is FunctionExpression) {
        final parent = current.parent;
        if (parent is ArgumentList) {
          final call = parent.parent;
          if (call is MethodInvocation && call.methodName.name == 'listen') {
            return true;
          }
        }
      }
    }
    return false;
  }
}
