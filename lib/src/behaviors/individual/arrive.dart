import '../../core/agent.dart';
import '../../core/steering_behavior.dart';
import '../../core/validation.dart';
import '../../math/vec2.dart';

/// Reduces desired speed linearly between a stop radius and a slowing radius.
final class Arrive implements SteeringBehavior {
  /// Requires slowingRadius > stopRadius >= 0 and responseTime > 0.
  Arrive(
    this.target, {
    this.slowingRadius = 100,
    this.stopRadius = 1,
    this.responseTime = 0.25,
  }) {
    nonNegative(stopRadius, 'stopRadius');
    positive(slowingRadius, 'slowingRadius');
    positive(responseTime, 'responseTime');
    if (slowingRadius <= stopRadius) {
      throw ArgumentError('slowingRadius must exceed stopRadius');
    }
  }

  /// Destination.
  final Vec2 target;

  /// Distance beyond which desired speed is maxSpeed.
  final double slowingRadius;

  /// Distance inside which desired speed is zero; braking remains bounded.
  final double stopRadius;

  /// Velocity response time in seconds.
  final double responseTime;

  @override
  Vec2 calculate(SteeringAgent agent, double dt) {
    nonNegative(dt, 'dt');
    final offset = target - agent.position;
    final ratio = ((offset.length - stopRadius) / (slowingRadius - stopRadius))
        .clamp(0.0, 1.0);
    final desired = offset.normalized * (agent.maxSpeed * ratio);
    return ((desired - agent.velocity) / responseTime)
        .limited(agent.maxAcceleration);
  }
}
