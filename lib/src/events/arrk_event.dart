/// Base type for all domain-level facts that travel through `ArrkEventBus`.
///
/// Events are **past-tense facts** ("UserAuthenticated", "OrderPlaced"),
/// never commands ("PleaseRefresh", "RefreshBalance"). The publisher
/// records what happened; subscribers decide what to do. The
/// `event_naming_past_tense` lint enforces the naming.
///
/// [ArrkEvent] is plain `abstract` — a package boundary cannot seal. Each
/// product seals its own event families (one sealed base per feature
/// library, extending [ArrkEvent]) so the exhaustiveness checker can reason
/// over the product's full set.
abstract class ArrkEvent {
  const ArrkEvent({required this.firedAt});

  /// When the publishing usecase / session-state mutation completed.
  final DateTime firedAt;
}
