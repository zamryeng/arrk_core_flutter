// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:arrk_core_flutter/events.dart' as _i722;
import 'package:arrk_core_flutter/session.dart' as _i212;
import 'package:arrk_core_flutter/viewmodel.dart' as _i690;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../features/greeting/data/greetings_repo.dart' as _i549;
import '../features/greeting/domain/dtos/greeting_draft_dto.dart' as _i139;
import '../features/greeting/domain/use_cases/send_greeting_use_case.dart'
    as _i179;
import '../features/greeting/ui/compose_greeting_vm.dart' as _i86;
import '../features/greeting/ui/preview_greeting_vm.dart' as _i800;
import 'app_module.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appModule = _$AppModule();
    gh.factory<_i549.GreetingsRepo>(() => _i549.GreetingsRepo());
    gh.singleton<_i722.ArrkEventBus>(() => appModule.eventBus);
    gh.lazySingleton<_i690.MessageDisplayHandler>(
      () => appModule.messageHandler,
    );
    gh.lazySingleton<_i212.ArrkSessionManager>(
      () => appModule.sessionManager(gh<_i722.ArrkEventBus>()),
    );
    gh.factory<_i179.SendGreetingUseCase>(
      () => _i179.SendGreetingUseCase(
        gh<_i549.GreetingsRepo>(),
        gh<_i722.ArrkEventBus>(),
      ),
    );
    gh.factory<_i86.ComposeGreetingVm>(
      () => _i86.ComposeGreetingVm(gh<_i179.SendGreetingUseCase>()),
    );
    gh.factoryParam<_i800.PreviewGreetingVm, _i139.GreetingDraftDto, dynamic>(
      (draft, _) =>
          _i800.PreviewGreetingVm(draft, gh<_i179.SendGreetingUseCase>()),
    );
    return this;
  }
}

class _$AppModule extends _i460.AppModule {}
