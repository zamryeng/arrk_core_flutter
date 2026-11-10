import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';

/// A snapshot of the running session: who and where.
///
/// Immutable. [ArrkSessionRepo] owns the current value and emits a new
/// snapshot on every change.
@immutable
class ArrkSession {
  const ArrkSession({this.deviceId, this.locale, this.country, this.isOpen = false});

  /// The session before `ArrkSessionRepo.open` completes.
  static const closed = ArrkSession();

  /// Stable device identifier, once the session is open.
  final String? deviceId;

  /// The active locale, once resolved.
  final Locale? locale;

  /// ISO 3166-1 alpha-2 country code, when known.
  final String? country;

  /// True after `ArrkSessionRepo.open` has completed.
  final bool isOpen;

  ArrkSession copyWith({String? deviceId, Locale? locale, String? country, bool? isOpen}) =>
      ArrkSession(
        deviceId: deviceId ?? this.deviceId,
        locale: locale ?? this.locale,
        country: country ?? this.country,
        isOpen: isOpen ?? this.isOpen,
      );

  @override
  bool operator ==(Object other) =>
      other is ArrkSession &&
      other.deviceId == deviceId &&
      other.locale == locale &&
      other.country == country &&
      other.isOpen == isOpen;

  @override
  int get hashCode => Object.hash(deviceId, locale, country, isOpen);

  @override
  String toString() =>
      'ArrkSession(deviceId: $deviceId, locale: $locale, country: $country, isOpen: $isOpen)';
}
