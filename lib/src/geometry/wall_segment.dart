import '../math/vec2.dart';

/// An immutable nondegenerate finite wall segment.
final class WallSegment {
  /// Creates a segment whose endpoints must differ.
  WallSegment(this.start, this.end) {
    if ((end - start).length == 0) {
      throw ArgumentError('Wall endpoints must differ');
    }
  }

  /// First endpoint, also the default travel orientation.
  final Vec2 start;

  /// Last endpoint.
  final Vec2 end;

  /// Unit direction from start to end.
  Vec2 get direction => (end - start).normalized;

  /// Closest point, clamping the projection to the finite segment.
  Vec2 closestPoint(Vec2 point) {
    final distance =
        (point - start).dot(direction).clamp(0.0, (end - start).length);
    return start + direction * distance;
  }
}
