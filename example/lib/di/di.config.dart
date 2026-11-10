// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:arrk_core_flutter/events.dart' as _i722;
import 'package:arrk_core_flutter/network.dart' as _i223;
import 'package:arrk_core_flutter/session.dart' as _i212;
import 'package:arrk_core_flutter/view.dart' as _i148;
import 'package:arrk_core_flutter/viewmodel.dart' as _i690;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../common/overlay_message_handler.dart' as _i779;
import '../features/activity/data/activity_repo.dart' as _i190;
import '../features/activity/domain/use_cases/record_activity_use_case.dart'
    as _i62;
import '../features/greeting/data/greetings_repo.dart' as _i549;
import '../features/greeting/domain/dtos/greeting_draft_dto.dart' as _i139;
import '../features/greeting/domain/use_cases/send_greeting_use_case.dart'
    as _i179;
import '../features/greeting/ui/compose_greeting_vm.dart' as _i86;
import '../features/greeting/ui/preview_greeting_vm.dart' as _i800;
import '../features/session/data/example_session_repo.dart' as _i405;
import '../reactions/app_reactions.dart' as _i331;
import '../services/request_headers/example_request_headers.dart' as _i401;
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
    gh.singleton<_i148.ArrkMessageChannel>(() => appModule.messageChannel);
    gh.singleton<_i190.ActivityRepo>(() => _i190.ActivityRepo());
    gh.singleton<_i401.ExampleRequestHeaders>(
      () => _i401.ExampleRequestHeaders(),
    );
    gh.singleton<_i212.ArrkSessionRepo>(
      () => _i405.ExampleSessionRepo(gh<_i401.ExampleRequestHeaders>()),
    );
    gh.singleton<_i722.EventPublisher>(
      () => appModule.eventPublisher(gh<_i722.ArrkEventBus>()),
    );
    gh.singleton<_i722.EventStream>(
      () => appModule.eventStream(gh<_i722.ArrkEventBus>()),
    );
    gh.singleton<_i690.MessageSink>(
      () => appModule.messageSink(gh<_i148.ArrkMessageChannel>()),
    );
    gh.singleton<_i148.MessageStream>(
      () => appModule.messageStream(gh<_i148.ArrkMessageChannel>()),
    );
    gh.singleton<_i223.RequestHeadersProvider>(
      () => appModule.requestHeaders(gh<_i401.ExampleRequestHeaders>()),
    );
    gh.factory<_i62.RecordActivityUseCase>(
      () => _i62.RecordActivityUseCase(gh<_i190.ActivityRepo>()),
    );
    gh.singleton<_i331.AppReactions>(
      () => _i331.AppReactions(
        gh<_i722.EventStream>(),
        gh<_i62.RecordActivityUseCase>(),
      ),
    );
    gh.factory<_i179.SendGreetingUseCase>(
      () => _i179.SendGreetingUseCase(
        gh<_i549.GreetingsRepo>(),
        gh<_i722.EventPublisher>(),
      ),
    );
    gh.singleton<_i779.OverlayMessageHandler>(
      () => _i779.OverlayMessageHandler(gh<_i148.MessageStream>()),
    );
    gh.factory<_i86.ComposeGreetingVm>(
      () => _i86.ComposeGreetingVm(
        gh<_i179.SendGreetingUseCase>(),
        gh<_i690.MessageSink>(),
      ),
    );
    gh.factoryParam<_i800.PreviewGreetingVm, _i139.GreetingDraftDto, dynamic>(
      (draft, _) => _i800.PreviewGreetingVm(
        draft,
        gh<_i179.SendGreetingUseCase>(),
        gh<_i690.MessageSink>(),
      ),
    );
    return this;
  }
}

class _$AppModule extends _i460.AppModule {}
