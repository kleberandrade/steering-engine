import '../../core/agent.dart';
import '../../core/steering_behavior.dart';
import '../../core/validation.dart';
import '../../math/vec2.dart';
import '../../core/steering_math.dart';

/// Accelerates away from a fixed target; exact overlap has no escape direction.
final class Flee implements SteeringBehavior {
  /// Sets the threat and positive velocity response time in seconds.
  Flee(this.target, {this.responseTime = 0.25}) {
    positive(responseTime, 'responseTime');
  }

  /// Threat position.
  final Vec2 target;

  /// Time over which desired velocity is approached.
  final double responseTime;

  @override
  Vec2 calculate(SteeringAgent agent, double dt) {
    nonNegative(dt, 'dt');
    return steerToward(agent, target, responseTime, flee: true);
  }
}
