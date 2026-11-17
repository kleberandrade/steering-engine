import 'dart:math' as math;
import '../core/agent.dart';
import '../core/steering_behavior.dart';
import '../core/validation.dart';
import '../math/vec2.dart';
import '../geometry/circle_obstacle.dart';

/// An immutable result of looking for the first predicted circle intersection.
final class ObstacleThreat {
  const ObstacleThreat._(this.obstacle, this.entryDistance, this.expandedRadius,
      this.isOverlapping);

  /// Obstacle selected by the scan; exact entry ties preserve input order.
  final CircleObstacle obstacle;

  /// Distance along the forward ray to first contact; zero for overlap.
  final double entryDistance;

  /// Obstacle radius plus agent radius and safety margin.
  final double expandedRadius;

  /// Whether the agent center is already on or inside the expanded circle.
  final bool isOverlapping;
}

/// Predicts intersections with inflated static circles and steers away.
///
/// Compose before goal seeking in `PrioritySteering`.
/// This is a reactive heuristic, not collision resolution or a safety guarantee.
/// A stopped agent scans only for overlap because its heading is undefined.
final class ObstacleAvoidance implements SteeringBehavior {
  /// Copies obstacles and validates finite nonnegative tuning values.
  ///
  /// The forward scan length is max(minLookAhead, speed * lookAheadTime).
  /// Tangency counts as a threat. Centerline ties steer toward local +Y.
  ObstacleAvoidance(Iterable<CircleObstacle> obstacles,
      {this.agentRadius = 0,
      this.safetyMargin = 2,
      this.lookAheadTime = 1,
      this.minLookAhead = 40,
      this.brakingWeight = 0.5})
      : obstacles = List.unmodifiable(obstacles) {
    nonNegative(agentRadius, 'agentRadius');
    nonNegative(safetyMargin, 'safetyMargin');
    nonNegative(lookAheadTime, 'lookAheadTime');
    nonNegative(minLookAhead, 'minLookAhead');
    nonNegative(brakingWeight, 'brakingWeight');
    for (final obstacle in this.obstacles) {
      positive(obstacle.radius + agentRadius + safetyMargin, 'expandedRadius');
    }
  }

  /// Immutable obstacle list. Recreate this behavior when geometry changes.
  final List<CircleObstacle> obstacles;

  /// Physical agent radius used to inflate each obstacle.
  final double agentRadius;

  /// Extra clearance beyond the physical radii.
  final double safetyMargin;

  /// Prediction horizon in seconds.
  final double lookAheadTime;

  /// Minimum forward scan length in distance units.
  final double minLookAhead;

  /// Backward contribution relative to lateral steering; zero disables braking.
  final double brakingWeight;

  /// Forward scan length; rejects arithmetic overflow instead of using infinity.
  double scanDistance(SteeringAgent agent) {
    final predicted = agent.velocity.length * lookAheadTime;
    nonNegative(predicted, 'predictedDistance');
    return math.max(minLookAhead, predicted);
  }

  /// Returns the first ray entry, or null when there is no local threat.
  ///
  /// This read-only query can be used to draw debug geometry without advancing
  /// any behavior state. It also detects overlap behind or beside the agent.
  ObstacleThreat? findThreat(SteeringAgent agent) {
    final heading = agent.velocity.normalized;
    final side = Vec2(-heading.y, heading.x);
    final scan = scanDistance(agent);
    ObstacleThreat? nearest;
    for (final obstacle in obstacles) {
      final offset = obstacle.center - agent.position;
      final radius = obstacle.radius + agentRadius + safetyMargin;
      final overlapping = offset.length <= radius;
      var entry = 0.0;
      if (!overlapping) {
        if (heading.length == 0) continue;
        final lateral = _dot(offset, side);
        if (lateral.abs() > radius) continue;
        final along = _dot(offset, heading);
        // Divide first to avoid squaring world-scale distances.
        final ratio = lateral / radius;
        final halfChord = radius * math.sqrt(math.max(0, 1 - ratio * ratio));
        entry = along - halfChord;
        if (!entry.isFinite) {
          throw ArgumentError('Entry distance is not representable');
        }
        if (entry < 0 || entry > scan) continue;
      }
      if (nearest == null || entry < nearest.entryDistance) {
        nearest = ObstacleThreat._(obstacle, entry, radius, overlapping);
      }
    }
    return nearest;
  }

  @override
  Vec2 calculate(SteeringAgent agent, double dt) {
    nonNegative(dt, 'dt');
    final threat = findThreat(agent);
    if (threat == null) return Vec2.zero;
    final heading =
        agent.velocity.length == 0 ? Vec2(1, 0) : agent.velocity.normalized;
    final side = Vec2(-heading.y, heading.x);
    if (threat.isOverlapping) {
      final away = agent.position - threat.obstacle.center;
      final direction = away.length == 0 ? side : away.normalized;
      return (direction * agent.maxAcceleration).limited(agent.maxAcceleration);
    }
    final lateral = _dot(threat.obstacle.center - agent.position, side);
    final turn = lateral > 0 ? -side : side;
    final direction = (turn - heading * brakingWeight).normalized;
    return (direction * agent.maxAcceleration).limited(agent.maxAcceleration);
  }
}

double _dot(Vec2 a, Vec2 b) {
  final result = a.x * b.x + a.y * b.y;
  if (!result.isFinite) throw ArgumentError('Projection is not representable');
  return result;
}
