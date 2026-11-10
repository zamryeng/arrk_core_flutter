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

/// Whether [type] is an interface type named in [names], or has a supertype
/// named in [names] (so a `FakeArrkEventBus` counts as an `ArrkEventBus`).
bool typeIsOrExtends(DartType? type, Set<String> names) {
  if (type is! InterfaceType) return false;
  final own = type.element.name;
  if (own != null && names.contains(own)) return true;
  for (final s in type.element.allSupertypes) {
    final name = s.element.name;
    if (name != null && names.contains(name)) return true;
  }
  return false;
}

/// Whether [node] sits inside a class that is, or transitively extends, a
/// class named in [names].
bool isInsideClassExtending(AstNode node, Set<String> names) {
  final clazz = node.thisOrAncestorOfType<ClassDeclaration>();
  if (clazz == null) return false;
  if (names.contains(clazz.namePart.typeName.lexeme)) return true;
  return hasSupertypeNamed(clazz, names);
}

/// The two halves of the event bus and the bus itself.
const eventBusTypes = {'ArrkEventBus', 'EventPublisher', 'EventStream'};

/// The types that can publish.
const publisherTypes = {'ArrkEventBus', 'EventPublisher'};

/// The types that can subscribe.
const subscriberTypes = {'ArrkEventBus', 'EventStream'};

/// The read side of the message channel, and the handler that reads it.
const messageReadTypes = {'MessageStream', 'ArrkMessageChannel', 'ArrkMessageHandler'};
