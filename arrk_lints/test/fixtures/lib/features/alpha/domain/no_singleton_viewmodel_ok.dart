import '../../../_stubs.dart';

// OK: a factory-scoped VM carries no singleton annotation.
class GoodVm extends ArrkViewModel {}

// OK: @singleton on a non-ViewModel is out of this rule's scope.
@singleton
class SomeService {}

// OK: @Singleton() on a non-ViewModel is fine.
@Singleton()
class AnotherService {}
