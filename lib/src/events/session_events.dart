import 'dart:ui' show Locale;

import 'arrk_event.dart';

/// Fires when the active session locale changes via
/// `ArrkSessionManager.updateLocale`. Subscribers invalidate locale-scoped
/// caches.
class SessionLocaleChanged extends ArrkEvent {
  const SessionLocaleChanged({
    required this.locale,
    required super.firedAt,
  });

  final Locale locale;
}

/// Fires when the active session country changes via
/// `ArrkSessionManager.updateCountry`. Subscribers refresh country-scoped
/// data.
class SessionCountryChanged extends ArrkEvent {
  const SessionCountryChanged({
    required this.countryCode,
    required super.firedAt,
  });

  final String countryCode;
}
