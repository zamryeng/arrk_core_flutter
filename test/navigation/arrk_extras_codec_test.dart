import 'package:flutter_test/flutter_test.dart';
import 'package:arrk_core_flutter/navigation.dart';

// ---------------------------------------------------------------------------
// A simple two-field type registered in the test codec
// ---------------------------------------------------------------------------

class _Point {
  const _Point(this.x, this.y);

  final int x;
  final int y;

  Map<String, dynamic> toMap() => {'x': x, 'y': y};

  static _Point fromMap(Map<String, dynamic> map) =>
      _Point(map['x'] as int, map['y'] as int);

  @override
  bool operator ==(Object other) =>
      other is _Point && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

// ---------------------------------------------------------------------------
// Test codec: registers _Point
// ---------------------------------------------------------------------------

final class _TestCodec extends ArrkExtrasCodec {
  const _TestCodec();

  @override
  List<ArrkExtraType<Object>> get types => [
    ArrkExtraType<_Point>(
      name: 'Point',
      encode: (p) => p.toMap(),
      decode: (payload) => _Point.fromMap(payload! as Map<String, dynamic>),
    ),
  ];
}

const _codec = _TestCodec();

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('encode → decode round-trip', () {
    test('registered type round-trips correctly', () {
      const input = _Point(3, 7);
      final encoded = _codec.encode(input);
      final decoded = _codec.decode(encoded);
      expect(decoded, equals(input));
    });

    test('round-trip preserves field values', () {
      const original = _Point(-10, 255);
      final decoded = _codec.decode(_codec.encode(original)) as _Point;
      expect(decoded.x, -10);
      expect(decoded.y, 255);
    });
  });

  group('DateTime built-in', () {
    test('DateTime round-trips via ISO-8601', () {
      final dt = DateTime(2026, 6, 15, 12, 30, 45);
      final encoded = _codec.encode(dt);
      final decoded = _codec.decode(encoded);
      expect(decoded, equals(dt));
    });

    test('DateTime encode produces [DateTime, isoString] envelope', () {
      final dt = DateTime(2026, 1, 1);
      final encoded = _codec.encode(dt) as List<Object?>;
      expect(encoded[0], 'DateTime');
      expect(encoded[1], dt.toIso8601String());
    });
  });

  group('null passthrough', () {
    test('encode(null) returns null', () {
      final encoded = _codec.encode(null);
      expect(encoded, isNull);
    });

    test('decode(null) returns null', () {
      final decoded = _codec.decode(null);
      expect(decoded, isNull);
    });
  });

  group('unregistered type', () {
    test('encode throws FormatException for unregistered type', () {
      // An object not registered in the codec.
      expect(
        () => _codec.encode(_UnregisteredType()),
        throwsFormatException,
      );
    });
  });

  group('unknown name on decode', () {
    test('decode throws FormatException for unknown type name', () {
      // Encode-like input with a name not in the registry.
      final input = <Object?>['UnknownTypeName', <String, dynamic>{'field': 'value'}];
      expect(
        () => _codec.decode(input),
        throwsFormatException,
      );
    });
  });
}

/// An unregistered type — not listed in the codec.
class _UnregisteredType {}
