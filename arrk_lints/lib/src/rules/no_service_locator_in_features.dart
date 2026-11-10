import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'ast_helpers.dart';
import 'lint_paths.dart';

/// Bans service-locator lookups (`ServiceLocator.get<…>()`, `GetIt.I<…>()`,
/// `GetIt.instance<…>()`) where they hide dependencies:
///
///   1. anywhere inside a feature's `domain/` — use constructor injection;
///   2. inside method bodies of `ArrkViewModel` subclasses wherever they live
///      (VMs live under `ui/`) — a VM's dependencies arrive at construction,
///      never mid-method.
///
/// Exempt:
///   - constructor initializers and default parameter values — the sanctioned
///     fallback-injection pattern
///     (`MyVm([Handler? h]) : h = h ?? ServiceLocator.get<Handler>()`);
///   - route-builder files under `ui/.navigation/`, where views get their
///     `model:` constructed;
///   - non-VM code in the UI layer (a widget constructing `model:` inline).
class NoServiceLocatorInFeatures extends AnalysisRule {
  NoServiceLocatorInFeatures()
    : super(
        name: _name,
        description:
            'Feature domain and ViewModel method bodies must use constructor '
            'injection, not service-locator lookups mid-method.',
      );

  static const _name = 'no_service_locator_in_features';

  static const _code = LintCode(
    _name,
    'Service-locator lookup inside feature domain or a ViewModel method '
    'body. Use constructor injection instead.',
    correctionMessage:
        'Inject the dependency through the constructor. ServiceLocator.get / '
        'GetIt lookups hide dependencies and break testability. (Constructor '
        'fallback initializers and ui/.navigation/ route builders are exempt.)',
    severity: DiagnosticSeverity.WARNING,
  );

  static final _pattern = RegExp(
    r'^(ServiceLocator\.get|GetIt\.(I|instance))$',
  );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final path = context.unitPath;
    // Route-builder files construct views and their `model:` — that is the
    // sanctioned place for locator lookups.
    if (isInUiNavigation(path)) return;
    final visitor = _Visitor(this, inFeatureDomain: isInFeatureDomain(path));
    registry.addFunctionExpressionInvocation(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, {required this.inFeatureDomain});

  final AnalysisRule rule;
  final bool inFeatureDomain;

  // `ServiceLocator.get<T>()` parses as invoking the `get` getter's result:
  // FunctionExpressionInvocation with function `ServiceLocator.get`.
  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (NoServiceLocatorInFeatures._pattern.hasMatch(node.function.toSource())) {
      _reportIfBanned(node);
    }
  }

  // `ServiceLocator.get(...)` (non-generic) may parse as a MethodInvocation.
  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.realTarget?.toSource();
    final name = node.methodName.name;
    if (target == 'ServiceLocator' && name == 'get') {
      _reportIfBanned(node);
    } else if ((target == 'GetIt.I' || target == 'GetIt.instance') && name.isNotEmpty) {
      _reportIfBanned(node);
    }
  }

  void _reportIfBanned(AstNode node) {
    // Anywhere in a feature's domain/ is banned, as before.
    if (inFeatureDomain) {
      rule.reportAtNode(node);
      return;
    }
    // Elsewhere, only lookups inside an ArrkViewModel subclass's method body
    // are banned. Construction-time injection (constructor initializers,
    // default parameter values, field initializers) stays allowed.
    if (_isInVmMethodBody(node)) {
      rule.reportAtNode(node);
    }
  }

  /// Whether [node] sits inside the body of a method declared on an
  /// `ArrkViewModel` subclass. Constructor initializers/bodies, default
  /// parameter values, and field initializers are construction-time injection
  /// and return false; so does any code outside a VM (widgets constructing
  /// `model:`, top-level route builders, plain classes).
  bool _isInVmMethodBody(AstNode node) {
    for (AstNode? current = node; current != null; current = current.parent) {
      // A default parameter value is construction-time, even when it appears
      // in a method's parameter list.
      if (current is FormalParameterDefaultClause) return false;
      // Constructor initializers and constructor bodies are the sanctioned
      // fallback-injection site.
      if (current is ConstructorDeclaration) return false;
      // Field initializers run at construction time.
      if (current is FieldDeclaration) return false;
      if (current is MethodDeclaration) {
        final clazz = current.thisOrAncestorOfType<ClassDeclaration>();
        return clazz != null && hasSupertypeNamed(clazz, const {'ArrkViewModel'});
      }
    }
    return false;
  }
}
