import 'package:arrk_core_flutter/locator.dart';
import 'package:arrk_core_flutter/session.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'common/overlay_message_handler.dart';
import 'di/di.dart';
import 'reactions/app_reactions.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await ServiceLocator.get<ArrkSessionRepo>().open();
  ServiceLocator.get<OverlayMessageHandler>().start(); // before anything can push
  ServiceLocator.get<AppReactions>().start();
  runApp(const ExampleApp());
}
