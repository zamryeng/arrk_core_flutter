import 'dart:async';

import 'package:arrk_core_flutter/events.dart';
import 'package:arrk_core_flutter/testing.dart';
import 'package:flutter_test/flutter_test.dart';

sealed class _TestEvent extends ArrkEvent {
  const _TestEvent({required super.firedAt});
}

final class _ItemAdded extends _TestEvent {
  const _ItemAdded(this.id, {required super.firedAt});
  final int id;
}

final class _ItemRemoved extends _TestEvent {
  const _ItemRemoved(this.id, {required super.firedAt});
  final int id;
}

/// An event outside the family: the reactions must ignore it.
final class _Unrelated extends ArrkEvent {
  const _Unrelated({required super.firedAt});
}

class _RecordingReactions extends ArrkReactions<_TestEvent> {
  _RecordingReactions(super.events);

  final List<String> log = <String>[];

  /// Per-id gates so a test can hold `react` open.
  final Map<int, Completer<void>> gates = <int, Completer<void>>{};

  /// Ids whose `react` throws.
  final Set<int> throwing = <int>{};

  @override
  Future<void> react(_TestEvent event) async {
    final id = switch (event) {
      _ItemAdded(:final id) => id,
      _ItemRemoved(:final id) => id,
    };
    log.add('start $id');
    final gate = gates[id];
    if (gate != null) await gate.future;
    if (throwing.contains(id)) throw StateError('boom $id');
    log.add('end $id');
  }
}

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeArrkEventBus bus;
  late _RecordingReactions reactions;

  setUp(() {
    bus = FakeArrkEventBus();
    reactions = _RecordingReactions(bus)..start();
  });

  tearDown(() async {
    await reactions.dispose();
    bus.destroy();
  });

  final t = DateTime(2026);

  test('handles events one at a time, in fire order', () async {
    reactions.gates[1] = Completer<void>();
    bus
      ..fire(_ItemAdded(1, firedAt: t))
      ..fire(_ItemRemoved(2, firedAt: t));
    await _settle();

    // 2 has not started while 1 is still running.
    expect(reactions.log, ['start 1']);

    reactions.gates[1]!.complete();
    await _settle();
    expect(reactions.log, ['start 1', 'end 1', 'start 2', 'end 2']);
  });

  test('a throwing react does not stop later events', () async {
    reactions.throwing.add(1);
    bus
      ..fire(_ItemAdded(1, firedAt: t))
      ..fire(_ItemAdded(2, firedAt: t));
    await _settle();

    expect(reactions.log, ['start 1', 'start 2', 'end 2']);
    expect(reactions.isStarted, isTrue);
  });

  test('ignores events outside its family', () async {
    bus.fire(_Unrelated(firedAt: t));
    await _settle();
    expect(reactions.log, isEmpty);
  });

  test('dispose cancels the subscription', () async {
    await reactions.dispose();
    expect(reactions.isStarted, isFalse);

    bus.fire(_ItemAdded(1, firedAt: t));
    await _settle();
    expect(reactions.log, isEmpty);
  });

  test('start twice subscribes once', () async {
    reactions.start();
    bus.fire(_ItemAdded(1, firedAt: t));
    await _settle();
    expect(reactions.log, ['start 1', 'end 1']);
  });
}
