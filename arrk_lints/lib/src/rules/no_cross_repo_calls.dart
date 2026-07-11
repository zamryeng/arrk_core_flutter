// ClassDeclaration.body exposes no public `members` accessor yet (analyzer
// primary-constructor migration); `.members` remains the way to iterate.
// ignore_for_file: deprecated_member_use

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'ast_helpers.dart';

/// Repos never call repos. A class that extends/mixes-in `ArrkRepository`
/// (directly or transitively, best-effort by supertype names) must not
/// reference another type named `*Repo` / `*Repository` — not as a field
/// type, not as a constructor-parameter type, not as an identifier inside
/// its members. An operation spanning two repos is a usecase.
///
/// The class's own name and `ArrkRepository` itself are exempt, as is the
/// class header (extends/with/implements) — only member bodies and
/// declarations are scanned.
class NoCrossRepoCalls extends AnalysisRule {
  NoCrossRepoCalls()
    : super(
        name: _name,
        description:
            'Repos never call repos. An operation spanning two repos is a '
            'usecase that takes both.',
      );

  static const _name = 'no_cross_repo_calls';

  static const _code = LintCode(
    _name,
    "Repo references another repo ('{0}'). Repos never call repos; an "
    'operation spanning two repos is a usecase.',
    correctionMessage:
        'Move the multi-repo coordination into a usecase that takes both '
        'repos. Each repo stays a self-contained boundary over its own data.',
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
    if (!hasSupertypeNamed(node, const {'ArrkRepository'})) return;
    final ownName = node.namePart.typeName.lexeme;
    final collector = _RepoReferenceCollector(ownName);
    // Only members — the class header (extends ArrkRepository, or an
    // intermediate `extends SomeBaseRepo`) is not a cross-repo call.
    for (final member in node.members) {
      member.accept(collector);
    }
    for (final hit in collector.hits) {
      rule.reportAtNode(hit.node, arguments: [hit.name]);
    }
  }
}

class _RepoReference {
  _RepoReference(this.node, this.name);
  final AstNode node;
  final String name;
}

/// Collects type-shaped references (`NamedType`s and capitalized simple
/// identifiers) whose name ends in `Repo`/`Repository` and is neither the
/// enclosing repo itself nor the `ArrkRepository` base.
class _RepoReferenceCollector extends RecursiveAstVisitor<void> {
  _RepoReferenceCollector(this.ownName);

  final String ownName;
  final List<_RepoReference> hits = [];

  static final _repoSuffix = RegExp(r'(Repo|Repository)$');

  bool _isBanned(String name) {
    if (name == ownName || name == 'ArrkRepository') return false;
    if (name.isEmpty) return false;
    // Type-shaped names only (a lowercase `myRepo` variable is not a type
    // reference; its declared type is caught as a NamedType anyway).
    if (name[0].toUpperCase() != name[0]) return false;
    return _repoSuffix.hasMatch(name);
  }

  // Field types, constructor-parameter types, local types, return types,
  // instantiations (`OtherRepo()`).
  @override
  void visitNamedType(NamedType node) {
    if (_isBanned(node.name.lexeme)) {
      hits.add(_RepoReference(node, node.name.lexeme));
    }
    super.visitNamedType(node);
  }

  // Static access (`OtherRepo.instance`) resolves the class name as a plain
  // identifier, not a NamedType.
  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (_isBanned(node.name)) {
      hits.add(_RepoReference(node, node.name));
    }
    super.visitSimpleIdentifier(node);
  }
}
