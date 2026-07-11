import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';

/// Whether [node]'s class transitively extends/implements/mixes-in any type
/// whose name is in [names].
///
/// Uses the resolved element model so intermediate base classes are covered
/// (e.g. a VM that extends `PaginatedDataViewModel` which extends
/// `ArrkViewModel`).
bool hasSupertypeNamed(ClassDeclaration node, Set<String> names) {
  final element = node.declaredFragment?.element;
  if (element == null) return false;
  for (final type in element.allSupertypes) {
    final name = type.element.name;
    if (name != null && names.contains(name)) return true;
  }
  return false;
}

/// Whether [node] carries any of the given annotations (by simple name,
/// e.g. `singleton`, `lazySingleton`).
bool hasAnnotationNamed(ClassDeclaration node, Set<String> names) =>
    node.metadata.any((a) => names.contains(a.name.name));

/// The simple name of the static type of [expression], or null.
String? staticTypeName(Expression? expression) {
  final type = expression?.staticType;
  if (type is InterfaceType) return type.element.name;
  return null;
}
