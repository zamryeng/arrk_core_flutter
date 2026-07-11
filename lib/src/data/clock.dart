/// An indirection over [DateTime.now] for testable time-based logic.
///
/// Production code reads time through [Clock.current]. Tests swap in a
/// `FakeClock` (from `package:arrk_core_flutter/testing.dart`) by
/// reassigning [Clock.current] in `setUp` and restoring in `tearDown`.
///
/// Constructors that need a clock (e.g. [CachedStream]) accept an optional
/// `Clock? clock` parameter and fall back to [Clock.current] when null, so
/// production callers don't have to thread it through.
abstract class Clock {
  DateTime now();

  /// The ambient clock used by code that doesn't take an explicit [Clock].
  ///
  /// Reassign in tests to inject deterministic time. Restore in `tearDown`.
  static Clock current = const SystemClock();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
