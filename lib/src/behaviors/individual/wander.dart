import 'dart:math' as math;
import '../../core/agent.dart';
import '../../core/steering_behavior.dart';
import '../../core/validation.dart';
import '../../math/vec2.dart';
import '../../core/steering_math.dart';

/// Stateful wandering with an optional seeded pseudo-random stream.
///
/// Own one instance per agent. Matching seeds reproduce matching call sequences
/// on the same runtime; varying time steps need not produce the same trajectory.
final class Wander implements SteeringBehavior {
  /// Creates wander with angular jitter in radians per second.
  Wander(
      {int? seed,
      this.jitter = 2,
      this.distance = 50,
      this.radius = 25,
      this.responseTime = 0.25})
      : _random = math.Random(seed) {
    nonNegative(jitter, 'jitter');
    positive(distance, 'distance');
    nonNegative(radius, 'radius');
    positive(responseTime, 'responseTime');
  }

  final math.Random _random;
  double _angle = 0;

  /// Maximum magnitude of sampled angular change per second.
  final double jitter;

  /// Distance of the wandering circle ahead of the agent.
  final double distance;

  /// Wandering circle radius.
  final double radius;

  /// Velocity response time in seconds.
  final double responseTime;

  @override
  Vec2 calculate(SteeringAgent agent, double dt) {
    nonNegative(dt, 'dt');
    if (dt > 0) {
      _angle = (_angle + (_random.nextDouble() * 2 - 1) * jitter * dt) %
          (2 * math.pi);
    }
    final heading =
        agent.velocity.length == 0 ? Vec2(1, 0) : agent.velocity.normalized;
    final side = Vec2(-heading.y, heading.x);
    final offset = heading * (distance + math.cos(_angle) * radius) +
        side * (math.sin(_angle) * radius);
    return steerToward(agent, agent.position + offset, responseTime);
  }
}
