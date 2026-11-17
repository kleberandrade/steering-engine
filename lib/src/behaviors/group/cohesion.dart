import '../../core/agent.dart';
import '../../core/steering_behavior.dart';
import '../../core/validation.dart';
import '../../math/vec2.dart';
import '../../perception/agent_neighborhood.dart';
import 'group_math.dart';

/// Linear positional attraction toward the local center of neighbors.
///
/// This rule adds acceleration without subtracting shared velocity; a group
/// moving together does not lose its common motion merely due to cohesion.
final class Cohesion implements SteeringBehavior {
  /// Creates a rule with a finite positive interaction radius.
  Cohesion(this.neighborhood, {this.radius = 80}) {
    positive(radius, 'radius');
  }

  /// Shared snapshots from the current frame.
  final AgentNeighborhood neighborhood;

  /// Interaction radius and attraction distance scale, in distance units.
  final double radius;

  @override
  Vec2 calculate(SteeringAgent agent, double dt) {
    nonNegative(dt, 'dt');
    final direction = meanVector(neighborhood
        .neighborsFor(agent, radius: radius)
        .map((other) => (other.position - agent.position) / radius));
    return (direction * agent.maxAcceleration).limited(agent.maxAcceleration);
  }
}
