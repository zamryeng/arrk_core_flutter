import 'dart:ui' show Locale;

import 'package:arrk_core_flutter/events.dart';
import 'package:arrk_core_flutter/session.dart';

/// Minimal concrete session for the example: in-memory identity, no
/// persistence. A real product loads/stores identity and locale, and
/// composes auth credentials into [requestHeaders].
class ExampleSessionManager extends ArrkSessionManager {
  ExampleSessionManager({required ArrkEventBus eventBus}) : _eventBus = eventBus;

  final ArrkEventBus _eventBus;

  String? _deviceId;
  Locale? _locale;
  String? _country;
  bool _isOpen = false;
  final Map<String, String> _headers = <String, String>{};

  @override
  String? get deviceId => _deviceId;

  @override
  Locale? get locale => _locale;

  @override
  String? get country => _country;

  @override
  bool get isOpen => _isOpen;

  @override
  Map<String, String> get requestHeaders => Map<String, String>.unmodifiable(_headers);

  @override
  Future<void> open() async {
    if (_isOpen) return;
    _deviceId = 'example-device';
    _locale = const Locale('en');
    _buildHeaders();
    _isOpen = true;
    notifyListeners();
  }

  @override
  Future<bool> updateLocale(Locale newLocale) async {
    if (!_isOpen) return false;
    _locale = newLocale;
    _buildHeaders();
    notifyListeners();
    _eventBus.fire(SessionLocaleChanged(locale: newLocale, firedAt: DateTime.now()));
    return true;
  }

  @override
  Future<bool> updateCountry(String countryCode) async {
    if (!_isOpen || !RegExp(r'^[A-Z]{2}$').hasMatch(countryCode)) return false;
    _country = countryCode;
    _buildHeaders();
    notifyListeners();
    _eventBus.fire(SessionCountryChanged(countryCode: countryCode, firedAt: DateTime.now()));
    return true;
  }

  void _buildHeaders() {
    _headers
      ..clear()
      ..['Content-Type'] = 'application/json';
    if (_deviceId != null) _headers['X-Device-ID'] = _deviceId!;
    if (_locale != null) _headers['Accept-Language'] = _locale.toString().replaceAll('_', '-');
    if (_country != null) _headers['X-Country'] = _country!;
  }
}
