import '../math/vec2.dart';

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
