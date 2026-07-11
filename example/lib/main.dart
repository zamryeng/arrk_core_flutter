import 'package:arrk_core_flutter/locator.dart';
import 'package:arrk_core_flutter/session.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'di/di.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await ServiceLocator.get<ArrkSessionManager>().open();
  runApp(const ExampleApp());
}
