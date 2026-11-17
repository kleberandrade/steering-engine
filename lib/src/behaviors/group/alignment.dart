import '../../core/agent.dart';
import '../../core/steering_behavior.dart';
import '../../core/validation.dart';
import '../../math/vec2.dart';
import '../../perception/agent_neighborhood.dart';
import 'group_math.dart';

/// Matches the average neighbor velocity, with a bounded velocity response.
final class Alignment implements SteeringBehavior {
  /// Requires a positive radius and positive response time in seconds.
  Alignment(this.neighborhood, {this.radius = 80, this.responseTime = 0.25}) {
    positive(radius, 'radius');
    positive(responseTime, 'responseTime');
  }

  /// Shared snapshots from the current frame.
  final AgentNeighborhood neighborhood;

  /// Inclusive interaction radius in distance units.
  final double radius;

  /// Time over which desired velocity is approached, in seconds.
  final double responseTime;

  @override
  Vec2 calculate(SteeringAgent agent, double dt) {
    nonNegative(dt, 'dt');
    final neighbors = neighborhood.neighborsFor(agent, radius: radius);
    if (neighbors.isEmpty) return Vec2.zero;
    final desired = meanVector(neighbors.map((other) => other.velocity))
        .limited(agent.maxSpeed);
    return ((desired - agent.velocity) / responseTime)
        .limited(agent.maxAcceleration);
  }
}
