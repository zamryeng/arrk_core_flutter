import 'package:flutter/material.dart';

import '../locator/service_locator.dart';
import 'failure.dart';

/// The states a view model can be in. The UI selects how to render itself
/// from this value.
enum VmState {
  /// Initial state; no ongoing operation.
  none,

  /// An operation is running (e.g. loading data).
  busy,

  /// An operation ended in an error.
  error,

  /// An operation ended in a network connectivity error.
  noConnection,
}

/// Displays user-facing messages (toasts, banners) on behalf of view models.
///
/// Products register one implementation in DI; [ArrkViewModel] resolves it
/// when no handler is passed to the constructor.
abstract class MessageDisplayHandler {
  void showError(String message, [String? heading]);
  void showSuccess(String message, [String? heading]);
  void showWarning(String message, [String? heading]);
  void showInfo(String message, [String? heading]);
}

/// Base class for view models: [ChangeNotifier]s that hold UI state for one
/// screen or feature.
///
/// The view listens to an instance of this class and rebuilds from its
/// members; buttons and gestures call methods on it. View models are screen
/// glue — they route to repos and usecases, never carry business logic, and
/// are registered `@injectable` (factory), never singleton.
///
/// ```dart
/// class LoginViewModel extends ArrkViewModel {
///   Future<void> login(String email, String password) async {
///     setState(VmState.busy);
///     final result = await _accountRepo.signIn(email, password);
///     if (result.hasError) {
///       handleErrorAndSetVmState(result.error!);
///     } else {
///       setState(VmState.none);
///     }
///   }
/// }
/// ```
abstract class ArrkViewModel extends ChangeNotifier {
  ArrkViewModel([MessageDisplayHandler? messageHandler])
    : messageHandler = messageHandler ?? ServiceLocator.get<MessageDisplayHandler>();

  /// The handler used by [handleError] / [handleErrorAndSetVmState] to
  /// surface messages. Injected through the constructor, or resolved from
  /// the service locator when not provided.
  final MessageDisplayHandler messageHandler;

  VmState _viewState = VmState.none;

  /// Whether the view model has been disposed. Guards against notifying
  /// listeners of a disposed notifier.
  bool _disposed = false;

  Failure? _lastFailure;

  /// The most recent failure handled by this view model, for debugging or
  /// error display.
  Failure? get lastFailure => _lastFailure;

  /// The current state. The UI reads this to decide how to render (e.g. a
  /// loading indicator while [VmState.busy]).
  VmState get viewState => _viewState;

  /// True when the current state is [VmState.error] or [VmState.noConnection].
  bool get hasEncounteredError => _viewState == VmState.error || _viewState == VmState.noConnection;

  /// True when the current state is [VmState.busy].
  bool get isBusy => _viewState == VmState.busy;

  /// Marks the view model disposed; late notifications become no-ops.
  ///
  /// Override to release resources (cancel subscriptions, dispose
  /// controllers) — the `subscription_cancelled_in_dispose` lint checks the
  /// subscription half.
  @override
  void dispose() {
    super.dispose();
    _disposed = true;
  }

  /// Sets the state to [viewState] and notifies listeners.
  ///
  /// With a null [viewState] the state is left unchanged but listeners are
  /// still notified — useful when data changed without a state transition.
  /// No-ops after [dispose].
  @protected
  void setState([VmState? viewState]) {
    if (viewState != null) _viewState = viewState;
    if (!_disposed && hasListeners) notifyListeners();
  }

  /// Handles [failure] via [handleError], then sets the matching state:
  /// [VmState.noConnection] for a [NetworkFailure], [VmState.error]
  /// otherwise.
  @protected
  void handleErrorAndSetVmState(Failure failure, [String? heading]) {
    handleError(failure);

    if (failure is NetworkFailure) {
      setState(VmState.noConnection);
    } else {
      setState(VmState.error);
    }
  }

  /// Shows [failure]'s message through [messageHandler] and records it as
  /// [lastFailure]. Only acts while the view model has listeners (i.e. a
  /// mounted view).
  @protected
  void handleError(Failure failure, [String? heading]) {
    if (hasListeners) {
      messageHandler.showError(failure.message);
      _lastFailure = failure;
    }
  }
}
