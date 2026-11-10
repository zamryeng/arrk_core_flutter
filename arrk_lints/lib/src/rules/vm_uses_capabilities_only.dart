import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import 'ast_helpers.dart';
import 'lint_paths.dart';

/// View models use capabilities only. In a file that declares an
/// `ArrkViewModel` subclass, flags:
/// - an import of a product file under `lib/features/*/data/` or
///   `lib/services/` (`package:arrk_core_flutter/...` is allowed);
/// - in the VM class, a field or constructor parameter typed
///   `ArrkEventBus`, `EventPublisher` or `EventStream`;
/// - in the VM class, a field or constructor parameter typed
///   `MessageStream`, `ArrkMessageChannel` or `ArrkMessageHandler` (a VM
///   only holds `MessageSink`);
/// - in the VM class, a field or constructor parameter whose type extends
///   `ArrkRepository`.
class VmUsesCapabilitiesOnly extends AnalysisRule {
  VmUsesCapabilitiesOnly()
    : super(
        name: _name,
        description:
            'View models depend on capabilities (use cases) only — never on '
            'repos, services, the event bus, or the message read side.',
      );

  static const _name = 'vm_uses_capabilities_only';

  static const _code = LintCode(
    _name,
    'View model depends on {0}.',
    correctionMessage:
        'Inject a capability from domain/use_cases/ instead. Capabilities '
        'reach repos and publish events; view models call capabilities.',
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
  bool _importsChecked = false;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!hasSupertypeNamed(node, const {'ArrkViewModel'})) return;
    _checkImports(node);

    for (final member in node.body.members) {
      if (member is FieldDeclaration) {
        if (member.isStatic) continue;
        for (final variable in member.fields.variables) {
          final type = variable.declaredFragment?.element.type;
          final what = _forbidden(type);
          if (what != null) rule.reportAtToken(variable.name, arguments: [what]);
        }
      } else if (member is ConstructorDeclaration) {
        for (final parameter in member.parameters.parameters) {
          final element = parameter.declaredFragment?.element;
          // `this._x` takes the field's type; the field is reported.
          if (element == null || element is FieldFormalParameterElement) continue;
          final what = _forbidden(element.type);
          if (what != null) rule.reportAtNode(parameter, arguments: [what]);
        }
      }
    }
  }

  /// Reports data/ and services/ imports, once per file.
  void _checkImports(ClassDeclaration node) {
    if (_importsChecked) return;
    _importsChecked = true;
    final unit = node.thisOrAncestorOfType<CompilationUnit>();
    if (unit == null) return;
    for (final directive in unit.directives.whereType<ImportDirective>()) {
      final uri = directive.uri.stringValue ?? '';
      if (uri.startsWith('package:arrk_core_flutter/')) continue;
      final library = directive.libraryImport?.importedLibrary;
      final path = library?.firstFragment.source.fullName.replaceAll(r'\', '/');
      if (path == null) continue;
      if (isInFeatureData(path)) {
        rule.reportAtNode(directive.uri, arguments: ['a data-layer file ($uri)']);
      } else if (isInServices(path)) {
        rule.reportAtNode(directive.uri, arguments: ['a service ($uri)']);
      }
    }
  }

  static String? _forbidden(DartType? type) {
    if (typeIsOrExtends(type, eventBusTypes)) return 'the event bus';
    if (typeIsOrExtends(type, messageReadTypes)) {
      return 'the message read side (a VM only holds MessageSink)';
    }
    if (typeIsOrExtends(type, const {'ArrkRepository'})) return 'a repository';
    return null;
  }
}
