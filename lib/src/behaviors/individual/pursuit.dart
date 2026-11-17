import '../../core/agent.dart';
import '../../core/steering_behavior.dart';
import '../../core/validation.dart';
import '../../math/vec2.dart';
import '../../core/steering_math.dart';

/// Seeks a linearly predicted moving target, with a bounded prediction horizon.
final class Pursuit implements SteeringBehavior {
  /// Captures an immutable target snapshot. Recreate when the target moves.
  Pursuit(this.target, {this.maxPrediction = 1, this.responseTime = 0.25}) {
    nonNegative(maxPrediction, 'maxPrediction');
    positive(responseTime, 'responseTime');
  }

  /// Moving target snapshot.
  final SteeringAgent target;

  /// Maximum prediction in seconds; zero disables prediction.
  final double maxPrediction;

  /// Velocity response time in seconds.
  final double responseTime;

  @override
  Vec2 calculate(SteeringAgent agent, double dt) {
    nonNegative(dt, 'dt');
    return steerToward(
        agent, predictTarget(agent, target, maxPrediction), responseTime);
  }
}
