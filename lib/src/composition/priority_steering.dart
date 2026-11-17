import '../core/agent.dart';
import '../core/steering_behavior.dart';
import '../core/validation.dart';
import '../math/vec2.dart';

/// Selects the first acceleration exceeding a threshold, rather than summing.
final class PrioritySteering implements SteeringBehavior {
  /// Copies the ordered behaviors. Empty lists return zero acceleration.
  PrioritySteering(Iterable<SteeringBehavior> behaviors, {this.epsilon = 0.001})
      : behaviors = List.unmodifiable(behaviors) {
    nonNegative(epsilon, 'epsilon');
  }

  /// Highest priority first; lower entries are evaluated only if needed.
  final List<SteeringBehavior> behaviors;

  /// Minimum acceleration magnitude to consider a behavior active.
  final double epsilon;

  @override
  Vec2 calculate(SteeringAgent agent, double dt) {
    nonNegative(dt, 'dt');
    for (final behavior in behaviors) {
      final acceleration =
          behavior.calculate(agent, dt).limited(agent.maxAcceleration);
      if (acceleration.length > epsilon) return acceleration;
    }
    return Vec2.zero;
  }
}
