import 'agent.dart';
import 'behavior.dart';
import 'validation.dart';
import 'vec2.dart';

/// A behavior and its finite, nonnegative multiplier.
final class WeightedBehavior {
  /// Creates a weighted entry. Zero disables evaluation of the behavior.
  WeightedBehavior(this.behavior, {this.weight = 1}) {
    nonNegative(weight, 'weight');
  }

  /// Behavior to evaluate.
  final SteeringBehavior behavior;

  /// Relative contribution; weights are not normalized.
  final double weight;
}

/// Sums weighted accelerations, then caps the result to the agent's limit.
final class WeightedBlend implements SteeringBehavior {
  /// Copies entries so later changes to the source iterable have no effect.
  WeightedBlend(Iterable<WeightedBehavior> entries)
      : entries = List.unmodifiable(entries);

  /// Immutable blend configuration, evaluated in order.
  final List<WeightedBehavior> entries;

  @override
  Vec2 calculate(SteeringAgent agent, double dt) {
    nonNegative(dt, 'dt');
    var sum = Vec2.zero;
    for (final entry in entries) {
      if (entry.weight == 0) continue;
      sum = sum + entry.behavior.calculate(agent, dt) * entry.weight;
    }
    return sum.limited(agent.maxAcceleration);
  }
}

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
