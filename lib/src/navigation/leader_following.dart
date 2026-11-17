import '../behaviors/individual/arrive.dart';
import '../composition/priority_steering.dart';
import '../core/agent.dart';
import '../core/steering_behavior.dart';
import '../core/validation.dart';
import '../geometry/circle_obstacle.dart';
import '../math/vec2.dart';
import 'obstacle_avoidance.dart';

/// Arrives behind a leader snapshot while giving local clearance precedence.
final class LeaderFollowing implements SteeringBehavior {
  /// Recreate when the leader moves. A stationary leader uses fallbackDirection
  /// (default +X); callers may retain the last observed heading explicitly.
  LeaderFollowing(this.leader,
      {this.distance = 40,
      this.avoidanceRadius = 15,
      double slowingRadius = 60,
      double stopRadius = 1,
      double responseTime = .25,
      Vec2? fallbackDirection}) {
    positive(distance, 'distance');
    nonNegative(avoidanceRadius, 'avoidanceRadius');
    if (distance <= avoidanceRadius) {
      throw ArgumentError('distance must exceed avoidanceRadius');
    }
    final fallback = fallbackDirection ?? Vec2(1, 0);
    positive(fallback.length, 'fallbackDirection');
    final direction = leader.velocity.length == 0
        ? fallback.normalized
        : leader.velocity.normalized;
    target = leader.position - direction * distance;
    final arrival = Arrive(target,
        slowingRadius: slowingRadius,
        stopRadius: stopRadius,
        responseTime: responseTime);
    _steering = avoidanceRadius == 0
        ? arrival
        : PrioritySteering([
            ObstacleAvoidance(
                [CircleObstacle(leader.position, radius: avoidanceRadius)],
                safetyMargin: 0, minLookAhead: avoidanceRadius * 2),
            arrival
          ]);
  }

  /// Immutable leader observation.
  final SteeringAgent leader;

  /// Requested trailing distance.
  final double distance;

  /// Local leader exclusion radius; zero disables avoidance.
  final double avoidanceRadius;

  /// Trailing arrival target computed from the snapshot heading.
  late final Vec2 target;
  late final SteeringBehavior _steering;
  @override
  Vec2 calculate(SteeringAgent agent, double dt) {
    nonNegative(dt, 'dt');
    return identical(agent, leader)
        ? Vec2.zero
        : _steering.calculate(agent, dt);
  }
}
