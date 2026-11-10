import 'dart:async';
import 'dart:ui' show Locale;

import 'package:arrk_core_flutter/responses.dart';
import 'package:arrk_core_flutter/session.dart';
import 'package:injectable/injectable.dart';

import '../../../services/request_headers/example_request_headers.dart';

/// The session as repo-owned state. In memory, no persistence: a real
/// product loads and saves identity, locale and country here.
@Singleton(as: ArrkSessionRepo)
class ExampleSessionRepo extends ArrkSessionRepo {
  ExampleSessionRepo(this._headers);

  final ExampleRequestHeaders _headers;
  final StreamController<ArrkSession> _changes = StreamController<ArrkSession>.broadcast();
  ArrkSession _session = ArrkSession.closed;

  @override
  ArrkSession get session => _session;

  @override
  Stream<ArrkSession> get sessionStream async* {
    yield _session;
    yield* _changes.stream;
  }

  @override
  Future<StatusResponse> open() => runStatusWithGuard(() async {
    if (_session.isOpen) return StatusResponse.successful();
    _set(const ArrkSession(deviceId: 'example-device', locale: Locale('en'), isOpen: true));
    return StatusResponse.successful();
  });

  @override
  Future<StatusResponse> updateLocale(Locale newLocale) => runStatusWithGuard(() async {
    if (!_session.isOpen) return StatusResponse.failed(InputFailure(message: 'Session not open.'));
    _set(_session.copyWith(locale: newLocale));
    return StatusResponse.successful();
  });

  @override
  Future<StatusResponse> updateCountry(String countryCode) => runStatusWithGuard(() async {
    if (!_session.isOpen || !RegExp(r'^[A-Z]{2}$').hasMatch(countryCode)) {
      return StatusResponse.failed(InputFailure(message: 'Invalid country code.'));
    }
    _set(_session.copyWith(country: countryCode));
    return StatusResponse.successful();
  });

  void _set(ArrkSession next) {
    _session = next;
    _headers
      ..set('X-Device-ID', next.deviceId)
      ..set('Accept-Language', next.locale?.toLanguageTag())
      ..set('X-Country', next.country);
    _changes.add(next);
  }
}
