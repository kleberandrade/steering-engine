import 'dart:math' as math;

import '../core/validation.dart';

/// An immutable vector with finite components and representable magnitude.
final class Vec2 {
  /// Creates a vector. Invalid or unrepresentable values throw [ArgumentError].
  factory Vec2(double x, double y) {
    if (!x.isFinite || !y.isFinite || !_length(x, y).isFinite) {
      throw ArgumentError('Vector components and magnitude must be finite');
    }
    return Vec2._(x, y);
  }

  const Vec2._(this.x, this.y);

  /// The zero vector.
  static const zero = Vec2._(0, 0);

  /// Horizontal component.
  final double x;

  /// Vertical component.
  final double y;

  /// Euclidean magnitude, calculated without squaring large components.
  double get length => _length(x, y);

  /// Unit direction, or [zero] when this vector has no direction.
  Vec2 get normalized => length == 0 ? zero : this / length;

  /// Adds two vectors.
  Vec2 operator +(Vec2 other) => Vec2(x + other.x, y + other.y);

  /// Subtracts two vectors.
  Vec2 operator -(Vec2 other) => Vec2(x - other.x, y - other.y);

  /// Reverses direction.
  Vec2 operator -() => Vec2(-x, -y);

  /// Multiplies by a finite scalar.
  Vec2 operator *(double scalar) {
    if (!scalar.isFinite) throw ArgumentError.value(scalar, 'scalar');
    return Vec2(x * scalar, y * scalar);
  }

  /// Divides by a finite nonzero scalar.
  Vec2 operator /(double scalar) {
    if (!scalar.isFinite || scalar == 0) {
      throw ArgumentError.value(scalar, 'scalar');
    }
    return Vec2(x / scalar, y / scalar);
  }

  /// Preserves direction and caps magnitude at [maximum].
  Vec2 limited(double maximum) {
    nonNegative(maximum, 'maximum');
    if (length <= maximum) return this;
    var result = normalized * maximum;
    if (result.length > maximum) {
      // Rounding can put a scaled unit vector a few ulps above the bound.
      result = result * (maximum / result.length * (1 - 1e-15));
      if (result.length > maximum) result = result * 0.5;
    }
    return result;
  }

  @override
  bool operator ==(Object other) =>
      other is Vec2 && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Vec2($x, $y)';
}

double _length(double x, double y) {
  final scale = math.max(x.abs(), y.abs());
  if (scale == 0) return 0;
  return scale *
      math.sqrt((x / scale) * (x / scale) + (y / scale) * (y / scale));
}
