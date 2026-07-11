import 'package:arrk_core_flutter/locator.dart';
import 'package:injectable/injectable.dart';

import 'di.config.dart';

/// DI bootstrap: the generated `init` extension is handed to the package's
/// [ServiceLocator.configure] seam. Regenerate with
/// `dart run build_runner build --delete-conflicting-outputs`.
@InjectableInit(initializerName: 'init', preferRelativeImports: true, asExtension: true)
Future<void> configureDependencies() => ServiceLocator.configure((locator) => locator.init());
