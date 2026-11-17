import 'agent.dart';
import 'behavior.dart';
import 'behaviors.dart';
import 'validation.dart';
import 'vec2.dart';

/// An immutable, ordered collection of waypoint positions.
final class SteeringPath {
  /// Copies a nonempty route. Set [loop] to connect the last point to the first.
  SteeringPath(Iterable<Vec2> waypoints, {this.loop = false})
      : waypoints = List.unmodifiable(waypoints) {
    if (this.waypoints.isEmpty) {
      throw ArgumentError('A path requires at least one waypoint');
    }
  }

  /// Positions visited in their supplied order, including any repeated points.
  final List<Vec2> waypoints;

  /// Whether traversal restarts after the final waypoint.
  final bool loop;
}

/// Stateful waypoint following with bounded arrival at each local destination.
///
/// Own one follower per agent. Route geometry may be shared. Intermediate points
/// advance when the current position enters [waypointRadius]. A nonlooping route
/// retains the final point and brakes with [Arrive]. This is capture-radius
/// following, not closest-segment projection or global pathfinding.
final class FollowPath implements SteeringBehavior {
  /// Creates a follower starting at waypoint zero.
  ///
  /// Requires slowingRadius > stopRadius >= 0, waypointRadius > stopRadius,
  /// and responseTime > 0. All distances use the agent's coordinate units.
  FollowPath(this.path,
      {this.waypointRadius = 10,
      this.slowingRadius = 50,
      this.stopRadius = 1,
      this.responseTime = 0.25}) {
    nonNegative(stopRadius, 'stopRadius');
    positive(waypointRadius, 'waypointRadius');
    positive(slowingRadius, 'slowingRadius');
    positive(responseTime, 'responseTime');
    if (slowingRadius <= stopRadius || waypointRadius <= stopRadius) {
      throw ArgumentError('Slowing and waypoint radii must exceed stopRadius');
    }
  }

  /// Shared immutable route configuration.
  final SteeringPath path;

  /// Distance at which intermediate points are considered visited.
  final double waypointRadius;

  /// Distance inside which arrival slows down toward each waypoint.
  final double slowingRadius;

  /// Distance inside which desired speed becomes zero.
  final double stopRadius;

  /// Positive velocity response time in seconds.
  final double responseTime;

  int _waypointIndex = 0;

  /// Index of the current destination; updated during positive-dt evaluation.
  int get waypointIndex => _waypointIndex;

  /// Position of the current destination.
  Vec2 get currentTarget => path.waypoints[_waypointIndex];

  /// Rewinds traversal to the first waypoint without changing the route.
  void reset() => _waypointIndex = 0;

  @override
  Vec2 calculate(SteeringAgent agent, double dt) {
    nonNegative(dt, 'dt');
    if (dt > 0) {
      // At most n-1 transitions avoids an infinite cycle with overlapping points.
      for (var skipped = 0; skipped < path.waypoints.length - 1; skipped++) {
        if ((currentTarget - agent.position).length > waypointRadius) break;
        if (_waypointIndex == path.waypoints.length - 1) {
          if (!path.loop) break;
          _waypointIndex = 0;
        } else {
          _waypointIndex++;
        }
      }
    }
    return Arrive(currentTarget,
            slowingRadius: slowingRadius,
            stopRadius: stopRadius,
            responseTime: responseTime)
        .calculate(agent, dt);
  }
}
