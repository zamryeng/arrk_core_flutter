import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../domain/arrk_view_model.dart';

/// Hosts a view model for one screen: provides it to the subtree, drives its
/// lifecycle, and rebuilds the [builder] on every notification.
///
/// Views render, VMs hold — [ArrkView] is the seam between them. The route
/// builder constructs the VM (typically `ServiceLocator.get<MyVm>()`) and
/// hands it in as [model]; [autoDispose] disposes it with the widget.
///
/// ```dart
/// ArrkView<LoginViewModel>(
///   model: ServiceLocator.get<LoginViewModel>(),
///   initState: (vm) => vm.onInit(),
///   builder: (vm, context) => LoginScreen(vm: vm),
/// )
/// ```
///
/// [T] The view model type, extending [ArrkViewModel].
class ArrkView<T extends ArrkViewModel> extends StatefulWidget {
  /// Creates an [ArrkView].
  ///
  /// [model] is the view model instance provided to the subtree; [builder]
  /// builds the widget tree from it. [initState] runs during widget
  /// initialization; [postFrameCallback] after the first frame. [keepAlive]
  /// preserves the state when not visible (via
  /// [AutomaticKeepAliveClientMixin]).
  const ArrkView({
    super.key,
    required this.model,
    required this.builder,
    this.autoDispose = true,
    this.initState,
    this.postFrameCallback,
    this.keepAlive = false,
  });

  /// The view model provided to the builder and the subtree.
  final T model;

  /// Whether to dispose [model] when this widget is disposed.
  final bool autoDispose;

  /// Optional callback run in `initState`, receiving the view model. Errors
  /// are caught and logged, never thrown into the framework.
  final void Function(T vm)? initState;

  /// Optional callback run after the first frame, receiving the view model.
  /// Errors are caught and logged.
  final void Function(T vm)? postFrameCallback;

  /// Builds the widget tree. Receives the (watched) view model and the
  /// context under the provider, so descendants can `context.read<T>()`.
  final Widget Function(T vm, BuildContext context) builder;

  /// Whether to keep the state alive when not visible.
  final bool keepAlive;

  @override
  ArrkViewState<T> createState() => ArrkViewState<T>();
}

/// State for [ArrkView]: owns the view model lifecycle and provides it via
/// [ChangeNotifierProvider].
class ArrkViewState<T extends ArrkViewModel> extends State<ArrkView<T>>
    with AutomaticKeepAliveClientMixin {
  /// The hosted view model.
  late T model;

  @override
  void initState() {
    model = widget.model;

    final initState = widget.initState;
    if (initState != null) {
      try {
        initState(model);
      } catch (e, t) {
        Logger(widget.runtimeType.toString()).severe('Error in initState of ArrkViewState', e, t);
      }
    }

    final callback = widget.postFrameCallback;
    if (callback != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          callback(model);
        } catch (e, t) {
          Logger(
            widget.runtimeType.toString(),
          ).severe('Error in postFrameCallback of ArrkViewState', e, t);
        }
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    if (widget.autoDispose) model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.keepAlive) {
      super.build(context);
    }

    return ChangeNotifierProvider<T>.value(
      value: model,
      child: Builder(
        builder: (context) {
          try {
            return widget.builder(context.watch<T>(), context);
          } catch (e) {
            Logger(widget.runtimeType.toString()).severe('Error in builder of ArrkView: $e');
            return Container();
          }
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;
}

/// Rebuilds from an already-provided view model, via [Consumer].
///
/// Use inside a subtree hosted by [ArrkView] when a widget needs the VM but
/// shouldn't re-provide it.
///
/// [T] The view model type, extending [ArrkViewModel].
class ArrkViewBuilder<T extends ArrkViewModel> extends StatelessWidget {
  /// Creates an [ArrkViewBuilder]. [child] is passed through to [builder]
  /// untouched, for the subtree that doesn't depend on the view model.
  const ArrkViewBuilder({super.key, required this.builder, this.child});

  /// Builds the widget tree from the provided view model.
  final Widget Function(T vm, Widget? child) builder;

  /// Pass-through subtree independent of the view model.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Consumer<T>(child: child, builder: (_, value, child) => builder(value, child));
  }
}

/// Rebuilds only when one selected value on the view model changes, via
/// [Selector].
///
/// ```dart
/// ArrkViewSelector<ProfileViewModel, String>(
///   selector: (vm) => vm.userName,
///   builder: (userName, child) => Text('Hello, $userName!'),
/// )
/// ```
///
/// [T] The view model type. [E] The selected value's type — must support
/// equality comparison.
class ArrkViewSelector<T extends ArrkViewModel, E extends Object?> extends StatelessWidget {
  /// Creates an [ArrkViewSelector].
  const ArrkViewSelector({super.key, required this.selector, required this.builder, this.child});

  /// Selects the value whose changes trigger rebuilds.
  final E Function(T model) selector;

  /// Builds the widget tree from the selected value.
  final Widget Function(E value, Widget? child) builder;

  /// Pass-through subtree independent of the selected value.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Selector<T, E>(
      selector: (_, model) => selector(model),
      child: child,
      builder: (_, value, child) => builder(value, child),
    );
  }
}
