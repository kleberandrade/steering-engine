import 'dart:math' as math;
import 'agent.dart';
import '../math/vec2.dart';

/// Converts a desired target direction into bounded acceleration.
Vec2 steerToward(SteeringAgent agent, Vec2 target, double time,
    {bool flee = false}) {
  final offset = flee ? agent.position - target : target - agent.position;
  final desired = offset.normalized * agent.maxSpeed;
  return ((desired - agent.velocity) / time).limited(agent.maxAcceleration);
}

/// Predicts constant-velocity motion within a configured time horizon.
Vec2 predictTarget(SteeringAgent agent, SteeringAgent target, double horizon) {
  final distance = (target.position - agent.position).length;
  final time =
      agent.maxSpeed == 0 ? 0.0 : math.min(horizon, distance / agent.maxSpeed);
  return target.position + target.velocity * time;
}
