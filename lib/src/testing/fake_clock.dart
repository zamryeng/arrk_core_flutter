import '../data/clock.dart';

/// Deterministic [Clock] for tests.
///
/// Construct at a fixed instant, then advance time explicitly. Pass it to
/// any constructor taking a `Clock?` (e.g. `CachedStream`), or assign it to
/// the ambient [Clock.current] in `setUp` (restore the original in
/// `tearDown`).
///
/// ```dart
/// late Clock original;
/// late FakeClock clock;
/// setUp(() {
///   original = Clock.current;
///   clock = FakeClock();
///   Clock.current = clock;
/// });
/// tearDown(() => Clock.current = original);
///
/// // ... clock.advance(const Duration(seconds: 31));
/// ```
class FakeClock implements Clock {
  FakeClock([DateTime? start]) : _now = start ?? DateTime(2026, 1, 1);

  DateTime _now;

  @override
  DateTime now() => _now;

  /// Moves time forward by [duration].
  void advance(Duration duration) => _now = _now.add(duration);

  /// Jumps to an absolute instant.
  void setTo(DateTime instant) => _now = instant;
}
