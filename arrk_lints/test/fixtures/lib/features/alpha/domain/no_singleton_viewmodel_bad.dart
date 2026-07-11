import '../../../_stubs.dart';

// expect_lint: no_singleton_viewmodel (const-instance form)
@singleton
class BadSingletonVm extends ArrkViewModel {}

// expect_lint: no_singleton_viewmodel (lazy const-instance form)
@lazySingleton
class BadLazyVm extends PaginatedDataViewModel {}

// expect_lint: no_singleton_viewmodel (constructor-call form)
@Singleton()
class BadSingletonCtorVm extends ArrkViewModel {}

// expect_lint: no_singleton_viewmodel (lazy constructor-call form)
@LazySingleton()
class BadLazySingletonCtorVm extends ArrkViewModel {}
