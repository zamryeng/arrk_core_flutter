import 'dart:convert';

/// One codec entry: how to round-trip values of [T] through the
/// `['TypeName', payload]` envelope [ArrkExtrasCodec] writes.
///
/// [encode] returns a JSON-encodable payload (usually a `Map` via `toMap()`);
/// [decode] rebuilds the value from that payload.
class ArrkExtraType<T extends Object> {
  const ArrkExtraType({
    required this.name,
    required Object? Function(T value) encode,
    required T Function(Object? payload) decode,
  }) : _encode = encode,
       _decode = decode;

  /// Stable wire name for the type. Renaming it breaks previously-issued
  /// deep links — treat it as persisted data.
  final String name;

  final Object? Function(T value) _encode;
  final T Function(Object? payload) _decode;

  bool matches(Object value) => value is T;

  Object? encode(Object value) => _encode(value as T);

  T decode(Object? payload) => _decode(payload);
}

/// Base for a product's GoRouter extras codec: serializes route `extra`
/// objects (Dtos, screen args) for web history and deep-link round-trips.
///
/// The product's codec extends this, lists its types, and is handed to
/// `GoRouter(extraCodec:)`:
///
/// ```dart
/// final class TallyExtrasCodec extends ArrkExtrasCodec {
///   const TallyExtrasCodec();
///
///   @override
///   List<ArrkExtraType<Object>> get types => [
///     ArrkExtraType<BoardDraftDto>(
///       name: 'BoardDraftDto',
///       encode: (dto) => dto.toMap(),
///       decode: (map) => BoardDraftDto.fromMap(map! as Map<String, dynamic>),
///     ),
///   ];
/// }
/// ```
///
/// The envelope is `[name, payload]`. [DateTime] is built in (ISO-8601);
/// everything else must be registered — an unregistered type throws
/// [FormatException] at encode/decode time, surfacing the gap immediately
/// rather than as a silently-lossy link.
abstract class ArrkExtrasCodec extends Codec<Object?, Object?> {
  const ArrkExtrasCodec();

  /// The product's registered extra types. Order is irrelevant; names must
  /// be unique.
  List<ArrkExtraType<Object>> get types;

  @override
  Converter<Object?, Object?> get decoder => _ArrkExtraDecoder(types);

  @override
  Converter<Object?, Object?> get encoder => _ArrkExtraEncoder(types);
}

class _ArrkExtraDecoder extends Converter<Object?, Object?> {
  const _ArrkExtraDecoder(this._types);

  final List<ArrkExtraType<Object>> _types;

  @override
  Object? convert(Object? input) {
    if (input == null) return null;
    final inputAsList = input as List<Object?>;
    final name = inputAsList[0];
    final payload = inputAsList[1];

    if (name == 'DateTime') return DateTime.parse(payload! as String);

    for (final type in _types) {
      if (type.name == name) return type.decode(payload);
    }
    throw FormatException('Unable to parse input: $input');
  }
}

class _ArrkExtraEncoder extends Converter<Object?, Object?> {
  const _ArrkExtraEncoder(this._types);

  final List<ArrkExtraType<Object>> _types;

  @override
  Object? convert(Object? input) {
    if (input == null) return null;

    if (input is DateTime) return <Object>['DateTime', input.toIso8601String()];

    for (final type in _types) {
      if (type.matches(input)) return <Object?>[type.name, type.encode(input)];
    }
    throw FormatException('Cannot encode type: ${input.runtimeType}');
  }
}
