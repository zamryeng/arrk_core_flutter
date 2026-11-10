import 'dart:ui' show Locale;

import '../data/arrk_repository.dart';
import '../domain/arrk_responses.dart';
import 'arrk_session.dart';

/// The session as state: one owner, read as a value or a stream.
///
/// The session (device, locale, country, open) is state, not an event.
/// It lives in this repo and moves as a stream. Nothing fires an event when
/// it changes: anything that cares watches [sessionStream]. Widgets that
/// render locale- or country-driven UI read it too.
///
/// Products ship one concrete subclass, registered as a singleton. It
/// persists the session and writes the matching headers into the product's
/// `RequestHeadersProvider`.
///
/// ```dart
/// @Singleton(as: ArrkSessionRepo)
/// class SessionRepo extends ArrkSessionRepo { ... }
/// ```
abstract class ArrkSessionRepo extends ArrkRepository {
  /// The current session. [ArrkSession.closed] until [open] completes.
  ArrkSession get session;

  /// The current session, then every change. Replays the current value to
  /// each new listener.
  Stream<ArrkSession> get sessionStream;

  /// Opens the session: resolves identity, loads the saved locale and
  /// country, and builds the request headers. Call once at startup, before
  /// anything sends a request.
  Future<StatusResponse> open();

  /// Sets the locale, saves it and updates the request headers. Fails when
  /// the session is not open or the locale is rejected.
  Future<StatusResponse> updateLocale(Locale newLocale);

  /// Sets the country (ISO 3166-1 alpha-2), saves it and updates the request
  /// headers. Fails when the session is not open or the code is rejected.
  Future<StatusResponse> updateCountry(String countryCode);
}
