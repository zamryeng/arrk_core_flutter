import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'lint_paths.dart';

/// Bans `try` statements in a feature's `domain/`. The domain consumes
/// `DataResponse`/`StatusResponse` — failures arrive as values, not thrown
/// exceptions. Guards live in the data layer only, where raw sources are
/// wrapped at the boundary.
class NoTryCatchInDomain extends AnalysisRule {
  NoTryCatchInDomain()
    : super(
        name: _name,
        description:
            'Feature domain must not guard with try/catch. Failures arrive '
            'as DataResponse/StatusResponse values from the data layer.',
      );

  static const _name = 'no_try_catch_in_domain';

  static const _code = LintCode(
    _name,
    'try/catch inside feature domain.',
    correctionMessage:
        'Domain consumes DataResponse/StatusResponse; guards live in the '
        'data layer only. Catch at the data boundary and return a response '
        'value.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!isInFeatureDomain(context.unitPath)) return;
    registry.addTryStatement(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitTryStatement(TryStatement node) {
    rule.reportAtToken(node.tryKeyword);
  }
}
