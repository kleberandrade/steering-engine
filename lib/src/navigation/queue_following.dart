import '../core/agent.dart';
import '../core/steering_behavior.dart';
import '../core/validation.dart';
import '../math/vec2.dart';
import '../perception/agent_neighborhood.dart';

/// Filters a movement behavior to brake behind the nearest forward lane occupant.
///
/// This is spatial queuing, not a task queue or a global FIFO reservation system.
/// Rebuild from each shared frame; bounded braking cannot resolve existing contacts.
final class QueueFollowing implements SteeringBehavior {
  /// Copies the lane direction as a unit vector (default +X). Spacing, laneRadius,
  /// lookAhead and responseTime must be finite and positive.
  QueueFollowing(this.neighborhood,
      {required this.movement,
      Vec2? direction,
      this.spacing = 25,
      this.laneRadius = 10,
      this.lookAhead = 100,
      this.responseTime = .25})
      : direction = (direction ?? Vec2(1, 0)).normalized {
    positive(this.direction.length, 'direction');
    positive(spacing, 'spacing');
    positive(laneRadius, 'laneRadius');
    positive(lookAhead, 'lookAhead');
    positive(responseTime, 'responseTime');
    _queryRadius = Vec2(lookAhead, laneRadius).length;
  }

  /// Shared observation of lane occupants.
  final AgentNeighborhood neighborhood;

  /// Requested movement, evaluated once per calculation.
  final SteeringBehavior movement;

  /// Fixed forward lane unit direction.
  final Vec2 direction;

  /// Desired center-to-center longitudinal spacing.
  final double spacing;

  /// Maximum lateral center displacement within the lane.
  final double laneRadius;

  /// Maximum forward detection distance.
  final double lookAhead;

  /// Velocity response time in seconds.
  final double responseTime;
  late final double _queryRadius;

  /// Closest strictly forward lane occupant, preserving input order on ties.
  SteeringAgent? findBlocker(SteeringAgent agent) {
    SteeringAgent? nearest;
    var gap = double.infinity;
    final side = Vec2(-direction.y, direction.x);
    for (final other
        in neighborhood.neighborsFor(agent, radius: _queryRadius)) {
      final offset = other.position - agent.position;
      final along = offset.dot(direction);
      if (along > 0 &&
          along <= lookAhead &&
          offset.dot(side).abs() <= laneRadius &&
          along < gap) {
        nearest = other;
        gap = along;
      }
    }
    return nearest;
  }

  @override
  Vec2 calculate(SteeringAgent agent, double dt) {
    nonNegative(dt, 'dt');
    final requested =
        movement.calculate(agent, dt).limited(agent.maxAcceleration);
    final blocker = findBlocker(agent);
    if (blocker == null) return requested;
    final gap = (blocker.position - agent.position).dot(direction);
    final desired =
        (blocker.velocity.dot(direction) + (gap - spacing) / responseTime)
            .clamp(0.0, agent.maxSpeed);
    final allowed = (desired - agent.velocity.dot(direction)) / responseTime;
    final current = requested.dot(direction);
    if (current <= allowed) return requested;
    return (requested + direction * (allowed - current))
        .limited(agent.maxAcceleration);
  }
}
