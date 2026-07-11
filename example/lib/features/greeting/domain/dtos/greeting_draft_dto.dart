import '../models/greeting_tone.dart';

/// Carries the greeting flow's accumulated data across screens.
///
/// Immutable; each screen builds the next step's Dto via [copyWith] and
/// pushes it with the route. Registered in the app's extras codec so the
/// flow survives web history and deep-link round-trips.
class GreetingDraftDto {
  const GreetingDraftDto({
    this.recipientName = '',
    this.tone = GreetingTone.friendly,
    this.previewText = '',
  });

  final String recipientName;
  final GreetingTone tone;
  final String previewText;

  /// Business readiness lives on the Dto, never in a VM.
  bool get isComplete => recipientName.isNotEmpty && previewText.isNotEmpty;

  GreetingDraftDto copyWith({String? recipientName, GreetingTone? tone, String? previewText}) =>
      GreetingDraftDto(
        recipientName: recipientName ?? this.recipientName,
        tone: tone ?? this.tone,
        previewText: previewText ?? this.previewText,
      );

  Map<String, dynamic> toMap() => {
    'recipientName': recipientName,
    'tone': tone.name,
    'previewText': previewText,
  };

  factory GreetingDraftDto.fromMap(Map<String, dynamic> map) => GreetingDraftDto(
    recipientName: map['recipientName'] as String? ?? '',
    tone: GreetingTone.values.asNameMap()[map['tone'] as String?] ?? GreetingTone.friendly,
    previewText: map['previewText'] as String? ?? '',
  );
}
