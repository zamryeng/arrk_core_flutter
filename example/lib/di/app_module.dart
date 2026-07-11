import 'package:arrk_core_flutter/events.dart';
import 'package:arrk_core_flutter/session.dart';
import 'package:arrk_core_flutter/viewmodel.dart';
import 'package:injectable/injectable.dart';

import '../app.dart';
import '../common/snackbar_message_handler.dart';
import '../services/session_manager/example_session_manager.dart';

/// Registrations the generator can't derive: the library types and their
/// example implementations.
@module
abstract class AppModule {
  @singleton
  ArrkEventBus get eventBus => ArrkEventBus();

  @lazySingleton
  MessageDisplayHandler get messageHandler => SnackbarMessageHandler(scaffoldMessengerKey);

  @lazySingleton
  ArrkSessionManager sessionManager(ArrkEventBus eventBus) =>
      ExampleSessionManager(eventBus: eventBus);
}
