// ClassDeclaration.body exposes no public `members` accessor yet (analyzer
// primary-constructor migration); `.members` remains the way to iterate.
// ignore_for_file: deprecated_member_use

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import 'ast_helpers.dart';

/// Requires every `StreamSubscription` field on an `ArrkViewModel` subclass to
/// be cancelled in `dispose()`. Factory-scoped VMs must release repo / event
/// subscriptions when their screen leaves, or the repo keeps refreshing.
///
/// A field counts as cancelled when a `<field>.cancel()` invocation is reached
/// from `dispose()` — directly in the dispose body or inside a helper method
/// that `dispose()` calls. The `.cancel()` target is resolved to an actual
/// field via the element model (not a substring match), so:
///   - delegating to a helper (`dispose() => _cleanup();`) is honoured, and
///   - an unrelated `_other.cancel()` never satisfies a different field.
class SubscriptionCancelledInDispose extends AnalysisRule {
  SubscriptionCancelledInDispose()
    : super(
        name: _name,
        description:
            'StreamSubscription fields on a ViewModel must be cancelled in '
            'dispose(), or subscriptions leak past the screen lifecycle.',
      );

  static const _name = 'subscription_cancelled_in_dispose';

  static const _code = LintCode(
    _name,
    "Subscription '{0}' is not cancelled in dispose().",
    correctionMessage:
        "Call '{0}?.cancel()' in dispose(). Factory-scoped VMs must release "
        'repo and event-bus subscriptions when the screen leaves.',
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

    final subscriptionFields = <VariableDeclaration>[];
    final methodsByName = <String, MethodDeclaration>{};
    MethodDeclaration? dispose;

    for (final member in node.body.members) {
      if (member is FieldDeclaration) {
        final type = member.fields.type;
        if (type is NamedType && type.name.lexeme == 'StreamSubscription') {
          subscriptionFields.addAll(member.fields.variables);
        }
      } else if (member is MethodDeclaration) {
        methodsByName[member.name.lexeme] = member;
        if (member.name.lexeme == 'dispose') dispose = member;
      }
    }

    if (subscriptionFields.isEmpty) return;

    final disposeMethod = dispose;
    if (disposeMethod == null) {
      for (final field in subscriptionFields) {
        rule.reportAtToken(field.name, arguments: [field.name.lexeme]);
      }
      return;
    }

    // Field names cancelled along any path reachable from dispose(): the
    // dispose body plus helper methods it invokes.
    final cancelled = _cancelledFieldNames(disposeMethod, methodsByName);

    for (final field in subscriptionFields) {
      final name = field.name.lexeme;
      if (!cancelled.contains(name)) {
        rule.reportAtToken(field.name, arguments: [name]);
      }
    }
  }

  /// Names of fields whose `.cancel()` is reachable from [entry], following
  /// instance-method calls to other declared methods in [methodsByName].
  Set<String> _cancelledFieldNames(
    MethodDeclaration entry,
    Map<String, MethodDeclaration> methodsByName,
  ) {
    final cancelled = <String>{};
    final visited = <String>{};
    final queue = <MethodDeclaration>[entry];

    while (queue.isNotEmpty) {
      final method = queue.removeLast();
      if (!visited.add(method.name.lexeme)) continue;
      final collector = _CancelCollector();
      method.body.accept(collector);
      cancelled.addAll(collector.cancelledFieldNames);
      // Follow same-class method calls (helpers like `_cleanup()`).
      for (final called in collector.invokedMethodNames) {
        final target = methodsByName[called];
        if (target != null) queue.add(target);
      }
    }
    return cancelled;
  }
}

/// Walks a method body collecting:
///   - the names of fields targeted by a resolved `.cancel()` call, and
///   - the names of same-class methods invoked (so callers can follow them).
class _CancelCollector extends RecursiveAstVisitor<void> {
  final Set<String> cancelledFieldNames = {};
  final Set<String> invokedMethodNames = {};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'cancel') {
      final fieldName = _resolveFieldName(node.target);
      if (fieldName != null) cancelledFieldNames.add(fieldName);
    } else if (node.target == null || node.target is ThisExpression) {
      // A bare or `this.`-qualified call to another method on the same class —
      // a potential cancellation helper. Record its name so the caller can
      // recurse into it.
      invokedMethodNames.add(node.methodName.name);
    }
    super.visitMethodInvocation(node);
  }

  /// Resolves the receiver of a `.cancel()` call to the name of the instance
  /// field it refers to, using the element model. Returns `null` when the
  /// receiver is not an instance field (so an unrelated local or a different
  /// field never satisfies the check).
  String? _resolveFieldName(Expression? target) {
    // `_sub.cancel()` / `this._sub.cancel()` / `obj._sub.cancel()`.
    final Element? element;
    switch (target) {
      case SimpleIdentifier():
        element = target.element;
      case PrefixedIdentifier():
        element = target.identifier.element;
      case PropertyAccess():
        element = target.propertyName.element;
      default:
        return null;
    }
    // A field read resolves to its (implicit) getter or the field itself; both
    // share the field's name.
    if (element is GetterElement) return element.name;
    if (element is FieldElement) return element.name;
    return null;
  }
}
