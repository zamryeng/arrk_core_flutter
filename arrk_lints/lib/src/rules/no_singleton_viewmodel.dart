import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'ast_helpers.dart';

/// Bans `@singleton` / `@lazySingleton` on `ArrkViewModel` subclasses.
///
/// ViewModels are factory-scoped (`@injectable`). App-lifetime state belongs
/// in repos (data state) or the session manager (session state). Documented
/// exceptions use `// ignore: no_singleton_viewmodel` with a rationale.
class NoSingletonViewModel extends AnalysisRule {
  NoSingletonViewModel()
    : super(
        name: _name,
        description:
            'ViewModels must be factory-scoped (@injectable). '
            '@singleton/@lazySingleton on a ViewModel leaks state for the '
            'app lifetime.',
      );

  static const _name = 'no_singleton_viewmodel';

  static const _code = LintCode(
    _name,
    "'{0}' is a ViewModel annotated @singleton/@lazySingleton.",
    correctionMessage:
        'Use @injectable (factory scope). Move shared state into a repo or '
        'the session manager. If a singleton is truly justified, suppress '
        'with // ignore: no_singleton_viewmodel and document why.',
    severity: DiagnosticSeverity.WARNING,
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
    if (!hasSupertypeNamed(node, const {'ArrkViewModel'})) return;
    // Catch both the const-instance form (`@singleton`, `@lazySingleton`) and
    // the constructor-call form (`@Singleton()`, `@LazySingleton()`).
    const annotations = {
      'singleton',
      'lazySingleton',
      'Singleton',
      'LazySingleton',
    };
    if (!hasAnnotationNamed(node, annotations)) return;
    rule.reportAtToken(node.namePart.typeName, arguments: [node.namePart.typeName.lexeme]);
  }
}
