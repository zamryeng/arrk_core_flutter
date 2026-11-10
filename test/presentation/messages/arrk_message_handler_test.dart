import 'package:arrk_core_flutter/testing.dart';
import 'package:arrk_core_flutter/view.dart';
import 'package:arrk_core_flutter/viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingHandler extends ArrkMessageHandler {
  _RecordingHandler(super.messages, {super.clock});

  final List<UserMessage> shown = <UserMessage>[];
  final Set<String> throwing = <String>{};

  @override
  void show(UserMessage message) {
    if (throwing.contains(message.text)) throw StateError('boom');
    shown.add(message);
  }
}

class _Vm extends ArrkViewModel {
  _Vm(super.messageSink);

  void sent() => showSuccess('Sent.');
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late ArrkMessageChannel channel;
  late FakeClock clock;
  late _RecordingHandler handler;

  setUp(() {
    channel = ArrkMessageChannel();
    clock = FakeClock();
    handler = _RecordingHandler(channel, clock: clock)..start();
  });

  tearDown(() async {
    await handler.dispose();
    await channel.close();
  });

  test('a message pushed after the VM is disposed reaches the handler', () async {
    final vm = _Vm(channel)..dispose();
    vm.sent();
    await _settle();
    expect(handler.shown, const [UserMessage.success('Sent.')]);
  });

  test('two equal messages within the window are shown once; after it, again', () async {
    channel
      ..push(const UserMessage.error('Offline'))
      ..push(const UserMessage.error('Offline', heading: 'different heading, same text'));
    await _settle();
    expect(handler.shown, hasLength(1));

    clock.advance(const Duration(seconds: 1));
    channel.push(const UserMessage.error('Offline'));
    await _settle();
    expect(handler.shown, hasLength(1), reason: 'still inside the 2s window');

    clock.advance(const Duration(seconds: 1));
    channel.push(const UserMessage.error('Offline'));
    await _settle();
    expect(handler.shown, hasLength(2));
  });

  test('same text with a different kind is not merged', () async {
    channel
      ..push(const UserMessage.error('Done'))
      ..push(const UserMessage.success('Done'));
    await _settle();
    expect(handler.shown, hasLength(2));
  });

  test('a show that throws does not stop later messages', () async {
    handler.throwing.add('bad');
    channel
      ..push(const UserMessage.info('bad'))
      ..push(const UserMessage.info('good'));
    await _settle();
    expect(handler.shown.single.text, 'good');
    expect(handler.isStarted, isTrue);
  });

  test('a push with no listener is dropped', () async {
    await handler.dispose();
    channel.push(const UserMessage.info('lost'));
    handler.start();
    await _settle();
    expect(handler.shown, isEmpty);
  });

  test('dispose cancels the subscription', () async {
    await handler.dispose();
    expect(handler.isStarted, isFalse);
    channel.push(const UserMessage.info('after'));
    await _settle();
    expect(handler.shown, isEmpty);
  });
}
