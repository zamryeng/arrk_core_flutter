import 'package:arrk_core_flutter/events.dart';

/// The greeting feature's event family — sealed per product, as the plain
/// `ArrkEvent` base cannot be sealed across the package boundary.
sealed class GreetingEvent extends ArrkEvent {
  const GreetingEvent({required super.firedAt});
}

/// A greeting was delivered. Published by `SendGreetingUseCase` after the
/// repo confirms the send; `AppReactions` maps it to the activity log.
final class GreetingSent extends GreetingEvent {
  const GreetingSent({required this.recipientName, required super.firedAt});

  final String recipientName;
}
