import '../math/vec2.dart';
import '../core/validation.dart';

/// A static circular obstacle in the caller's distance units.
final class CircleObstacle {
  /// Creates a circle with a finite positive [radius].
  CircleObstacle(this.center, {required this.radius}) {
    positive(radius, 'radius');
  }

  /// World-space center.
  final Vec2 center;

  /// Physical obstacle radius, excluding agent size and clearance.
  final double radius;
}
