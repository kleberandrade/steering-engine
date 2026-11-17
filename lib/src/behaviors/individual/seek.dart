import '../../core/agent.dart';
import '../../core/steering_behavior.dart';
import '../../core/validation.dart';
import '../../math/vec2.dart';
import '../../core/steering_math.dart';
import 'arrive.dart';

/// Accelerates toward a fixed target; use [Arrive] to stop at the target.
final class Seek implements SteeringBehavior {
  /// Sets the target and positive velocity response time in seconds.
  Seek(this.target, {this.responseTime = 0.25}) {
    positive(responseTime, 'responseTime');
  }

  /// Target position.
  final Vec2 target;

  /// Time over which desired velocity is approached.
  final double responseTime;

  @override
  Vec2 calculate(SteeringAgent agent, double dt) {
    nonNegative(dt, 'dt');
    return steerToward(agent, target, responseTime);
  }
}
