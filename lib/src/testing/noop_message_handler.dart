import '../domain/arrk_view_model.dart';

/// No-op [MessageDisplayHandler] for VM tests.
///
/// `ArrkViewModel`'s constructor resolves `MessageDisplayHandler` via
/// `ServiceLocator.get<MessageDisplayHandler>()` when no handler is passed
/// in. Tests that don't bootstrap full DI must register this stub before
/// constructing any `ArrkViewModel`-based class.
///
/// ```dart
/// setUp(() {
///   final getIt = GetIt.instance;
///   if (!getIt.isRegistered<MessageDisplayHandler>()) {
///     getIt.registerSingleton<MessageDisplayHandler>(NoopMessageHandler());
///   }
/// });
/// ```
class NoopMessageHandler implements MessageDisplayHandler {
  @override
  void showError(String message, [String? heading]) {}
  @override
  void showInfo(String message, [String? heading]) {}
  @override
  void showSuccess(String message, [String? heading]) {}
  @override
  void showWarning(String message, [String? heading]) {}
}
