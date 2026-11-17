import 'dart:math' as math;

import 'agent.dart';
import 'behavior.dart';
import 'validation.dart';
import 'vec2.dart';

Vec2 _toward(SteeringAgent agent, Vec2 target, double time,
    {bool flee = false}) {
  final offset = flee ? agent.position - target : target - agent.position;
  final desired = offset.normalized * agent.maxSpeed;
  return ((desired - agent.velocity) / time).limited(agent.maxAcceleration);
}

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
    return _toward(agent, target, responseTime);
  }
}

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
    return _toward(agent, target, responseTime, flee: true);
  }
}

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

Vec2 _prediction(SteeringAgent agent, SteeringAgent target, double horizon) {
  final distance = (target.position - agent.position).length;
  final time =
      agent.maxSpeed == 0 ? 0.0 : math.min(horizon, distance / agent.maxSpeed);
  return target.position + target.velocity * time;
}

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
    return _toward(
        agent, _prediction(agent, target, maxPrediction), responseTime);
  }
}

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
    return _toward(
        agent, _prediction(agent, target, maxPrediction), responseTime,
        flee: true);
  }
}

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
    return _toward(agent, agent.position + offset, responseTime);
  }
}

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
