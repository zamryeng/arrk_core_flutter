import 'package:flutter/material.dart';

import 'failure.dart';
import 'messages/message_sink.dart';
import 'messages/user_message.dart';

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

/// Base class for view models: [ChangeNotifier]s that hold UI state for one
/// screen or feature.
///
/// The view listens to an instance of this class and rebuilds from its
/// members; buttons and gestures call methods on it. View models are screen
/// glue: they call capabilities (use cases) only — never repos, services or
/// the event bus — carry no business logic, and are registered `@injectable`
/// (factory), never singleton. They never navigate: a method returns what
/// the view needs to decide where to go.
///
/// ```dart
/// @injectable
/// class LoginViewModel extends ArrkViewModel {
///   LoginViewModel(this._signIn, super.messageSink);
///
///   final SignInUseCase _signIn;
///
///   /// True when signed in; the view navigates on true.
///   Future<bool> login(String email, String password) async {
///     setState(VmState.busy);
///     final result = await _signIn.withPassword(email, password);
///     if (result.hasError) {
///       handleErrorAndSetVmState(result.error!);
///       return false;
///     }
///     setState(VmState.none);
///     return true;
///   }
/// }
/// ```
abstract class ArrkViewModel extends ChangeNotifier {
  ArrkViewModel(this.messageSink);

  /// Where [handleError] and the `show*` helpers push user messages. The
  /// app's one `ArrkMessageHandler` reads and draws them, so a message
  /// pushed after this VM is disposed still shows.
  @protected
  final MessageSink messageSink;

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
    handleError(failure, heading);

    if (failure is NetworkFailure) {
      setState(VmState.noConnection);
    } else {
      setState(VmState.error);
    }
  }

  /// Pushes an error message with [failure]'s message and records it as
  /// [lastFailure]. Pushes even after [dispose].
  @protected
  void handleError(Failure failure, [String? heading]) {
    _lastFailure = failure;
    messageSink.push(UserMessage.error(failure.message, heading: heading));
  }

  /// Pushes a success message. Pushes even after [dispose].
  @protected
  void showSuccess(String text, [String? heading]) =>
      messageSink.push(UserMessage.success(text, heading: heading));

  /// Pushes a warning message. Pushes even after [dispose].
  @protected
  void showWarning(String text, [String? heading]) =>
      messageSink.push(UserMessage.warning(text, heading: heading));

  /// Pushes an info message. Pushes even after [dispose].
  @protected
  void showInfo(String text, [String? heading]) =>
      messageSink.push(UserMessage.info(text, heading: heading));
}
