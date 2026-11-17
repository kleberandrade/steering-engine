import '../../core/agent.dart';
import '../../core/steering_behavior.dart';
import '../../core/validation.dart';
import '../../math/vec2.dart';
import '../../perception/agent_neighborhood.dart';
import 'group_math.dart';

/// Local repulsion with linear distance falloff and bounded acceleration.
final class Separation implements SteeringBehavior {
  /// Creates a rule with a finite positive interaction radius.
  Separation(this.neighborhood, {this.radius = 25}) {
    positive(radius, 'radius');
  }

  /// Shared snapshots from the current frame.
  final AgentNeighborhood neighborhood;

  /// Interaction radius in distance units.
  final double radius;

  @override
  Vec2 calculate(SteeringAgent agent, double dt) {
    nonNegative(dt, 'dt');
    final neighbors = neighborhood.neighborsFor(agent, radius: radius);
    final direction = meanVector(neighbors.map((other) {
      final away = agent.position - other.position;
      // Normalizing zero yields zero; exact overlap invents no escape direction.
      return away.normalized * (1 - away.length / radius);
    }));
    return (direction * agent.maxAcceleration).limited(agent.maxAcceleration);
  }
}
