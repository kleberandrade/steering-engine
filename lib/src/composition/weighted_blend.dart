import '../core/agent.dart';
import '../core/steering_behavior.dart';
import '../core/validation.dart';
import '../math/vec2.dart';
import 'weighted_behavior.dart';

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
