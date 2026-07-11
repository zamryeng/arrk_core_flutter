import 'package:flutter/foundation.dart';
import 'dart:ui' show Locale;

/// Session foundation: device + app + user identity carrier.
///
/// One place for everything network plumbing, repos, and VMs need to read
/// about "who and where" the running session is. Products implement the
/// semantics (storage, onboarding flags, auth specifics); the library fixes
/// the surface other core types consume — notably [requestHeaders], read by
/// `DioNetworkService` as the single source of outgoing-request headers.
///
/// Mutators fire past-tense session events (`SessionLocaleChanged`,
/// `SessionCountryChanged`) on the `ArrkEventBus` so cross-feature
/// subscribers can react without reaching into other view models.
///
/// [ArrkSessionManager] is the ONE sanctioned [ChangeNotifier] outside
/// `ArrkViewModel` (the `no_change_notifier_outside_vm` lint knows it):
/// widgets that render locale/country-driven UI listen to it directly.
abstract class ArrkSessionManager extends ChangeNotifier {
  /// Stable device identifier, once the session is open.
  String? get deviceId;

  /// The active locale, once resolved.
  Locale? get locale;

  /// ISO 3166-1 alpha-2 country code, when known.
  String? get country;

  /// True after [open] has completed.
  bool get isOpen;

  /// Single source of truth for outgoing-request headers. Network
  /// interceptors must read from here — no other source.
  Map<String, String> get requestHeaders;

  /// Opens the session: resolve identity, load persisted locale/country,
  /// build [requestHeaders].
  Future<void> open();

  /// Updates the locale, persists it, rebuilds [requestHeaders], and fires
  /// `SessionLocaleChanged`. Returns false when the update was rejected.
  Future<bool> updateLocale(Locale newLocale);

  /// Updates the country, persists it, rebuilds [requestHeaders], and fires
  /// `SessionCountryChanged`. Returns false when the update was rejected.
  Future<bool> updateCountry(String countryCode);
}
