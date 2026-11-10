import 'package:arrk_core_flutter/events.dart';
import 'package:arrk_core_flutter/network.dart';
import 'package:arrk_core_flutter/view.dart';
import 'package:arrk_core_flutter/viewmodel.dart';
import 'package:injectable/injectable.dart';

import '../services/request_headers/example_request_headers.dart';

/// Registrations the generator can't derive: the library types and their
/// example implementations.
@module
abstract class AppModule {
  /// One bus, registered as itself and as both of its halves. Capabilities
  /// take [EventPublisher]; the reactions class takes [EventStream].
  @singleton
  ArrkEventBus get eventBus => ArrkEventBus();

  @singleton
  EventPublisher eventPublisher(ArrkEventBus bus) => bus;

  @singleton
  EventStream eventStream(ArrkEventBus bus) => bus;

  /// One message channel, registered under both halves. View models take
  /// [MessageSink]; the one `OverlayMessageHandler` takes [MessageStream].
  @singleton
  ArrkMessageChannel get messageChannel => ArrkMessageChannel();

  @singleton
  MessageSink messageSink(ArrkMessageChannel channel) => channel;

  @singleton
  MessageStream messageStream(ArrkMessageChannel channel) => channel;

  /// What a `DioNetworkService` registration would take.
  @singleton
  RequestHeadersProvider requestHeaders(ExampleRequestHeaders headers) => headers;
}
