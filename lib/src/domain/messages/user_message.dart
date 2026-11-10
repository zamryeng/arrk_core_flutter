import 'package:flutter/foundation.dart';

import 'user_message_kind.dart';

/// One message for the user: a toast, a banner, whatever the product draws.
///
/// View models push these onto a `MessageSink`; the app's one
/// `ArrkMessageHandler` reads them and draws them.
@immutable
class UserMessage {
  const UserMessage(this.kind, this.text, {this.heading});

  const UserMessage.error(String text, {String? heading}) : this(UserMessageKind.error, text, heading: heading);
  const UserMessage.success(String text, {String? heading})
    : this(UserMessageKind.success, text, heading: heading);
  const UserMessage.warning(String text, {String? heading})
    : this(UserMessageKind.warning, text, heading: heading);
  const UserMessage.info(String text, {String? heading}) : this(UserMessageKind.info, text, heading: heading);

  final UserMessageKind kind;

  /// The user-facing copy.
  final String text;

  /// Optional title shown above [text].
  final String? heading;

  @override
  bool operator ==(Object other) =>
      other is UserMessage && other.kind == kind && other.text == text && other.heading == heading;

  @override
  int get hashCode => Object.hash(kind, text, heading);

  @override
  String toString() => 'UserMessage(${kind.name}, "$text"${heading == null ? '' : ', heading: "$heading"'})';
}
