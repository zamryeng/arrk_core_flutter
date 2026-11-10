import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'ast_helpers.dart';
import 'lint_paths.dart';

/// Only the app's one `ArrkMessageHandler` reads user messages. Flags any
/// reference to `MessageStream` or `ArrkMessageChannel` except:
/// - in a class that extends `ArrkMessageHandler`;
/// - in DI registration and the composition root (`lib/di/`, `lib/app/`,
///   or a class annotated `@module`).
///
/// Everything else writes through `MessageSink`.
class MessageStreamRestriction extends AnalysisRule {
  MessageStreamRestriction()
    : super(
        name: _name,
        description:
            'MessageStream / ArrkMessageChannel are for the one '
            'ArrkMessageHandler and DI registration. Everything else takes '
            'MessageSink.',
      );

  static const _name = 'message_stream_restriction';

  static const _code = LintCode(
    _name,
    "'{0}' referenced outside the message handler and DI.",
    correctionMessage:
        'Take MessageSink and push. Only the ArrkMessageHandler subclass '
        'reads the stream; only DI wires the channel.',
    severity: DiagnosticSeverity.WARNING,
  );

  static const _types = {'MessageStream', 'ArrkMessageChannel'};

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (isInDi(context.unitPath)) return;
    registry.addNamedType(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitNamedType(NamedType node) {
    final name = node.name.lexeme;
    if (!MessageStreamRestriction._types.contains(name)) return;
    if (isInsideClassExtending(node, const {'ArrkMessageHandler'})) return;
    final clazz = node.thisOrAncestorOfType<ClassDeclaration>();
    if (clazz != null && hasAnnotationNamed(clazz, const {'module'})) return;
    rule.reportAtNode(node, arguments: [name]);
  }
}
