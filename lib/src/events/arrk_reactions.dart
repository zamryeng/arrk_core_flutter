import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'arrk_event.dart';
import 'event_stream.dart';

/// The product's one event subscriber.
///
/// Subscribes to the events of type [E] and maps each event to capability
/// calls. Events are handled one at a time, in fire order: the next event
/// waits until [react] for the previous one completes.
///
/// A product has exactly one reactions class. It never publishes (the
/// `no_event_fire_in_handler` lint enforces it), and view models and views
/// never subscribe.
///
/// ```dart
/// @singleton
/// class AppReactions extends ArrkReactions<AppEvent> {
///   AppReactions(super.events, this._recordActivity);
///
///   final RecordActivityUseCase _recordActivity;
///
///   @override
///   Future<void> react(AppEvent event) => switch (event) {
///     GreetingSent(:final recipientName) => _recordActivity.greetingSent(recipientName),
///   };
/// }
///
/// // main(), after DI:
/// ServiceLocator.get<AppReactions>().start();
/// ```
abstract class ArrkReactions<E extends ArrkEvent> {
  ArrkReactions(this._events);

  final EventStream _events;
  StreamSubscription<void>? _subscription;

  static final Logger _logger = Logger('ArrkReactions');

  /// Whether [start] has run and [dispose] has not.
  bool get isStarted => _subscription != null;

  /// Subscribes to [E] events. Calling it again while started does nothing.
  void start() {
    if (_subscription != null) return;
    _subscription = _events.on<E>().asyncMap(_reactSafely).listen(null);
  }

  /// Handles one event. Implement with an exhaustive `switch` over the
  /// product's sealed event family.
  ///
  /// If this throws, the error is logged and the next event is still
  /// handled.
  @protected
  Future<void> react(E event);

  /// Cancels the subscription. Events fired afterwards are not handled.
  Future<void> dispose() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }

  Future<void> _reactSafely(E event) async {
    try {
      await react(event);
    } catch (error, stackTrace) {
      _logger.severe('react(${event.runtimeType}) threw; continuing', error, stackTrace);
    }
  }
}
