import '../behaviors/individual/seek.dart';
import '../core/agent.dart';
import '../core/steering_behavior.dart';
import '../core/validation.dart';
import '../geometry/wall_segment.dart';
import '../math/vec2.dart';

/// Side of the oriented travel tangent where the agent's offset lies.
enum WallSide {
  /// Local normal (-tangent.y, tangent.x).
  left,

  /// Opposite local normal.
  right,
}

/// Seeks an offset target projected onto the nearest local finite wall segment.
final class WallFollowing implements SteeringBehavior {
  /// Copies walls. Positive lookAhead, maxDistance and responseTime are required;
  /// wallOffset is nonnegative. This is local guidance, not collision resolution.
  WallFollowing(Iterable<WallSegment> walls,
      {this.wallOffset = 20,
      this.lookAhead = 30,
      this.maxDistance = 100,
      this.responseTime = .25,
      this.side = WallSide.left,
      Vec2? fallbackDirection})
      : walls = List.unmodifiable(walls),
        fallbackDirection = (fallbackDirection ?? Vec2(1, 0)).normalized {
    nonNegative(wallOffset, 'wallOffset');
    positive(lookAhead, 'lookAhead');
    positive(maxDistance, 'maxDistance');
    positive(responseTime, 'responseTime');
    positive(this.fallbackDirection.length, 'fallbackDirection');
  }

  /// Immutable segment geometry in input order.
  final List<WallSegment> walls;

  /// Offset from the selected segment along its chosen normal.
  final double wallOffset;

  /// Probe and tangential target look-ahead distance.
  final double lookAhead;

  /// Probe acquisition distance; no nearby wall returns zero acceleration.
  final double maxDistance;

  /// Velocity response time in seconds.
  final double responseTime;

  /// Desired side relative to the oriented travel tangent.
  final WallSide side;

  /// Probe heading for a stopped agent.
  final Vec2 fallbackDirection;

  /// Read-only predicted target, or null when no segment is within acquisition.
  Vec2? targetFor(SteeringAgent agent) {
    final heading = agent.velocity.length == 0
        ? fallbackDirection
        : agent.velocity.normalized;
    final probe = agent.position + heading * lookAhead;
    WallSegment? selected;
    Vec2? projected;
    var distance = maxDistance;
    for (final wall in walls) {
      final point = wall.closestPoint(probe);
      final d = (point - probe).length;
      if (d <= distance && (selected == null || d < distance)) {
        selected = wall;
        projected = point;
        distance = d;
      }
    }
    if (selected == null) return null;
    var tangent = selected.direction;
    if (tangent.dot(heading) < 0) tangent = -tangent;
    final normal =
        Vec2(-tangent.y, tangent.x) * (side == WallSide.left ? 1.0 : -1.0);
    return projected! + tangent * lookAhead + normal * wallOffset;
  }

  @override
  Vec2 calculate(SteeringAgent agent, double dt) {
    nonNegative(dt, 'dt');
    final target = targetFor(agent);
    return target == null
        ? Vec2.zero
        : Seek(target, responseTime: responseTime).calculate(agent, dt);
  }
}
