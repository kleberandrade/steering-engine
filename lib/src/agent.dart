import 'validation.dart';
import 'vec2.dart';

/// Immutable kinematic state with velocity and acceleration limits.
final class SteeringAgent {
  /// Creates a state. Initial velocity must be within [maxSpeed].
  SteeringAgent(
      {required this.position,
      this.velocity = Vec2.zero,
      this.maxSpeed = 100,
      this.maxAcceleration = 200}) {
    nonNegative(maxSpeed, 'maxSpeed');
    nonNegative(maxAcceleration, 'maxAcceleration');
    if (velocity.length > maxSpeed) {
      throw ArgumentError('Initial velocity exceeds maxSpeed');
    }
  }

  /// Position in caller-defined distance units.
  final Vec2 position;

  /// Velocity in distance units per second.
  final Vec2 velocity;

  /// Maximum speed in distance units per second; zero disables movement.
  final double maxSpeed;

  /// Maximum acceleration in distance units per second squared.
  final double maxAcceleration;

  /// Creates a validated snapshot with selected values replaced.
  SteeringAgent copyWith(
          {Vec2? position,
          Vec2? velocity,
          double? maxSpeed,
          double? maxAcceleration}) =>
      SteeringAgent(
        position: position ?? this.position,
        velocity: velocity ?? this.velocity,
        maxSpeed: maxSpeed ?? this.maxSpeed,
        maxAcceleration: maxAcceleration ?? this.maxAcceleration,
      );
}
