import '../../core/agent.dart';
import '../../core/steering_behavior.dart';
import '../../core/validation.dart';
import '../../math/vec2.dart';

/// Brakes toward zero velocity with bounded acceleration.
final class Brake implements SteeringBehavior {
  /// Sets a positive velocity response time in seconds.
  Brake({this.responseTime = 0.25}) {
    positive(responseTime, 'responseTime');
  }

  /// Time over which velocity approaches zero.
  final double responseTime;

  @override
  Vec2 calculate(SteeringAgent agent, double dt) {
    nonNegative(dt, 'dt');
    return (-agent.velocity / responseTime).limited(agent.maxAcceleration);
  }
}
