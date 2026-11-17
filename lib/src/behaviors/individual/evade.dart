import '../../core/agent.dart';
import '../../core/steering_behavior.dart';
import '../../core/validation.dart';
import '../../math/vec2.dart';
import '../../core/steering_math.dart';

/// Flees a linearly predicted moving threat.
final class Evade implements SteeringBehavior {
  /// Captures a threat snapshot and a bounded prediction horizon in seconds.
  Evade(this.target, {this.maxPrediction = 1, this.responseTime = 0.25}) {
    nonNegative(maxPrediction, 'maxPrediction');
    positive(responseTime, 'responseTime');
  }

  /// Moving threat snapshot.
  final SteeringAgent target;

  /// Maximum prediction in seconds.
  final double maxPrediction;

  /// Velocity response time in seconds.
  final double responseTime;

  @override
  Vec2 calculate(SteeringAgent agent, double dt) {
    nonNegative(dt, 'dt');
    return steerToward(
        agent, predictTarget(agent, target, maxPrediction), responseTime,
        flee: true);
  }
}
