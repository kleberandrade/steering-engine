import '../core/steering_behavior.dart';
import '../core/validation.dart';

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
