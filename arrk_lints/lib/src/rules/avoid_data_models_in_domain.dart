import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'lint_paths.dart';

/// Keeps the data layer a closed box for domain/UI: no file under a feature's
/// `domain/`, `ui/`, navigation, or `lib/core/` may import its `data/models/`,
/// `data/sources/`, or `data/mappers/` — only the public `<x>_repo.dart` is.
/// Exempt: the feature's own `data/` folder, and `lib/services/`, whose
/// data-access backends map wire/database formats to domain types at the
/// boundary.
class AvoidDataModelsInDomain extends AnalysisRule {
  AvoidDataModelsInDomain()
    : super(
        name: _name,
        description:
            'Domain/UI must not import data/models, data/sources, or '
            'data/mappers. Only the repository class is part of the data '
            "layer's public surface (the service layer maps at the boundary "
            'and is exempt).',
      );

  static const _name = 'avoid_data_models_in_domain';

  static const _code = LintCode(
    _name,
    'Importing data-layer internals ({0}) from outside the data folder.',
    correctionMessage:
        'Expose what you need through the repository class. data/models, '
        'data/sources and data/mappers are private to data/.',
    severity: DiagnosticSeverity.WARNING,
  );

  static final _bannedSegments = <String>[
    'data/models/',
    'data/sources/',
    'data/mappers/',
  ];

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    // A file inside a feature's data/ folder may freely import its own internals.
    if (isInFeatureData(context.unitPath)) return;
    // The service layer (database/JSON data-access backends) legitimately
    // converts at the boundary — data-access implementations speak in domain
    // types, mapped at the boundary. Services sit below the domain layer, so
    // they are not the target of this rule, which protects domain/UI from
    // reaching into data internals.
    if (isInServices(context.unitPath)) return;
    registry.addImportDirective(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue;
    if (uri == null) return;
    for (final segment in AvoidDataModelsInDomain._bannedSegments) {
      if (uri.contains(segment)) {
        rule.reportAtNode(node.uri, arguments: [segment]);
        return;
      }
    }
  }
}
