import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'ast_helpers.dart';

/// `ArrkEvent` subclasses are past-tense facts (`UserAuthenticated`,
/// `TransactionSent`), never commands. Flags command-shaped names.
class EventNamingPastTense extends AnalysisRule {
  EventNamingPastTense()
    : super(
        name: _name,
        description:
            'ArrkEvent subclasses must be past-tense facts, not commands. '
            'Commands create action-at-a-distance.',
      );

  static const _name = 'event_naming_past_tense';

  static const _code = LintCode(
    _name,
    "'{0}' is a command-shaped event name.",
    correctionMessage:
        'Name events as past-tense facts (UserAuthenticated, TransactionSent). '
        'Subscribers decide what to do; the event only states what happened.',
    severity: DiagnosticSeverity.WARNING,
  );

  /// Imperative prefixes that signal a command rather than a fact. A trailing
  /// boundary (uppercase letter or end) avoids matching e.g. `Updated`.
  static final _commandPrefix = RegExp(
    r'^(Refresh|Update|Please|Do|Reload|Set|Fetch|Load|Make|Trigger|Send|Create|Delete|Remove|Add)(?=[A-Z]|$)',
  );

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
    if (!hasSupertypeNamed(node, const {'ArrkEvent'})) return;
    final name = node.namePart.typeName.lexeme;
    if (EventNamingPastTense._commandPrefix.hasMatch(name)) {
      rule.reportAtToken(node.namePart.typeName, arguments: [name]);
    }
  }
}
