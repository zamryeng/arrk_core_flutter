import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'lint_paths.dart';

/// Bans `BuildContext` in feature `domain/` & `data/` and in `lib/services/`,
/// whether as a parameter type, a stored field type, or a getter return type —
/// all three smuggle UI state into a context-free layer. UI lives in the UI
/// layer; everything below is context-free.
class NoBuildContextInDomainOrDataOrServices extends AnalysisRule {
  NoBuildContextInDomainOrDataOrServices()
    : super(
        name: _name,
        description:
            'domain/, data/, and services/ must not take BuildContext. '
            'Anything modal/dialog-shaped belongs in a UI helper.',
      );

  static const _name = 'no_build_context_in_domain_or_data_or_services';

  static const _code = LintCode(
    _name,
    'BuildContext parameter in a context-free layer (domain/data/services).',
    correctionMessage:
        'Move UI concerns to the UI layer. Pass plain data/booleans down, and '
        'let a UI helper own the BuildContext.',
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
    if (!isInServices(path) && !isInFeatureDomainOrData(path)) return;
    registry.addNamedType(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitNamedType(NamedType node) {
    if (node.name.lexeme != 'BuildContext') return;
    // Flag the three ways a context-free layer can hold onto a BuildContext:
    // as a formal parameter type (passing one in), a stored field type (keeping
    // one), or a getter return type (handing one out). Local variables / casts
    // inside a method body remain out of scope.
    if (_isParameterType(node) || _isFieldType(node) || _isGetterReturnType(node)) {
      rule.reportAtNode(node);
    }
  }

  bool _isParameterType(NamedType node) => node.thisOrAncestorOfType<FormalParameter>() != null;

  bool _isFieldType(NamedType node) {
    final field = node.thisOrAncestorOfType<FieldDeclaration>();
    // Only the declared field type counts, not a BuildContext merely mentioned
    // in an initializer expression.
    return field != null && identical(field.fields.type, node);
  }

  bool _isGetterReturnType(NamedType node) {
    final method = node.thisOrAncestorOfType<MethodDeclaration>();
    return method != null && method.isGetter && identical(method.returnType, node);
  }
}
