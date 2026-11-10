import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'ast_helpers.dart';

/// Handlers never publish. Flags:
/// - `fire(...)` inside an event-handler closure
///   (`bus.on<T>().listen((e) { bus.fire(...); })`);
/// - any reference to `EventPublisher` or `ArrkEventBus` inside a class that
///   extends `ArrkReactions`.
///
/// Re-publishing from a handler creates untraceable signal loops.
class NoEventFireInHandler extends AnalysisRule {
  NoEventFireInHandler()
    : super(
        name: _name,
        description:
            'Event handlers and the ArrkReactions class must not publish. '
            'Re-publishing inside a handler creates cycles.',
      );

  static const _name = 'no_event_fire_in_handler';

  static const _code = LintCode(
    _name,
    'Publishing from an event handler.',
    correctionMessage:
        'Handlers consume only. The reactions class calls capabilities; if a '
        'follow-up event is needed, the capability that caused the first '
        'event publishes it.',
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
    registry.addNamedType(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'fire') return;
    if (!typeIsOrExtends(node.realTarget?.staticType, publisherTypes)) return;
    // Inside an ArrkReactions class the type reference is already reported.
    if (isInsideClassExtending(node, const {'ArrkReactions'})) return;
    if (_isInsideListenClosure(node)) {
      rule.reportAtNode(node.methodName);
    }
  }

  @override
  void visitNamedType(NamedType node) {
    if (!publisherTypes.contains(node.name.lexeme)) return;
    if (!isInsideClassExtending(node, const {'ArrkReactions'})) return;
    rule.reportAtNode(node);
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
