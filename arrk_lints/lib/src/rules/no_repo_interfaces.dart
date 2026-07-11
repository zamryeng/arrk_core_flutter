import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'lint_paths.dart';

/// Bans the repo interface/implementation split:
///
///   - an ABSTRACT class named `*Repo` / `*Repository` under `lib/features/`;
///   - ANY class named `*RepoImpl` / `*RepositoryImpl`, anywhere.
///
/// A repo has exactly one implementation; an interface for it is speculative
/// indirection. Abstract repo bases in the core library itself
/// (`ArrkRepository`) do not live under `lib/features/` and are unaffected.
class NoRepoInterfaces extends AnalysisRule {
  NoRepoInterfaces()
    : super(
        name: _name,
        description:
            'Repos are concrete classes. No abstract *Repo/*Repository '
            'interfaces in features, and no *RepoImpl/*RepositoryImpl '
            'anywhere.',
      );

  static const _name = 'no_repo_interfaces';

  static const _code = LintCode(
    _name,
    "'{0}': repos are concrete classes; delete the interface, keep one "
    'concrete repo.',
    correctionMessage:
        'Collapse the interface/impl pair into a single concrete repo class. '
        'Test seams come from constructor-injected dependencies, not a repo '
        'interface.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(
      this,
      _Visitor(this, inFeatures: isInFeatures(context.unitPath)),
    );
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, {required this.inFeatures});

  final AnalysisRule rule;
  final bool inFeatures;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final nameToken = node.namePart.typeName;
    final name = nameToken.lexeme;
    // The Impl half of the split is banned anywhere — its existence implies
    // the interface half.
    if (name.endsWith('RepoImpl') || name.endsWith('RepositoryImpl')) {
      rule.reportAtToken(nameToken, arguments: [name]);
      return;
    }
    // The interface half: an abstract *Repo/*Repository inside a feature.
    if (!inFeatures) return;
    if (node.abstractKeyword == null) return;
    if (name.endsWith('Repo') || name.endsWith('Repository')) {
      rule.reportAtToken(nameToken, arguments: [name]);
    }
  }
}
