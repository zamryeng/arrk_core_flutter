/// Arrk's Flutter core: base classes and plumbing for the four-layer
/// architecture.
///
/// Umbrella export. Products may import this, or the per-layer barrels
/// (`viewmodel.dart`, `data.dart`, …) for narrower dependence. `testing.dart`
/// is deliberately NOT exported here — test seams are imported by test code
/// explicitly.
library;

export 'data.dart';
export 'events.dart';
export 'locator.dart';
export 'navigation.dart';
export 'network.dart';
export 'responses.dart';
export 'services.dart';
export 'session.dart';
export 'view.dart';
export 'viewmodel.dart';
