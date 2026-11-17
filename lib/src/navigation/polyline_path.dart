import '../core/validation.dart';
import '../math/vec2.dart';
import 'steering_path.dart';

/// One nonzero edge with a cumulative route offset.
final class PolylineSegment {
  const PolylineSegment._(
      this.start, this.end, this.startDistance, this.length, this.direction);

  /// First and last points of this edge.
  final Vec2 start, end;

  /// Distance from the route start to this edge's start.
  final double startDistance;

  /// Positive edge length.
  final double length;

  /// Unit tangent in traversal order.
  final Vec2 direction;
}

/// A finite-segment projection, optionally restricted to an arc-distance window.
final class PathProjection {
  const PathProjection._(this.segmentIndex, this.fraction, this.point,
      this.distanceAlong, this.distanceFromPath);

  /// Index in PolylinePath.segments, after skipping zero-length edges.
  final int segmentIndex;

  /// Clamped edge fraction in [0, 1].
  final double fraction;

  /// Position on the polyline.
  final Vec2 point;

  /// Route distance in [0, path.length], without loop lap count.
  final double distanceAlong;

  /// Euclidean distance from the query point to [point].
  final double distanceFromPath;
}

/// Immutable finite-edge geometry and arc-length queries for a SteeringPath.
///
/// Repeated consecutive vertices are skipped; all-coincident routes are rejected.
/// A looping path includes its closing edge. Geometry can be shared by followers.
final class PolylinePath {
  /// Copies precomputed geometry from an immutable route.
  PolylinePath(this.route) {
    final edges = <PolylineSegment>[];
    var total = 0.0;
    final count = route.waypoints.length - (route.loop ? 0 : 1);
    for (var i = 0; i < count; i++) {
      final start = route.waypoints[i];
      final end = route.waypoints[(i + 1) % route.waypoints.length];
      final delta = end - start;
      final size = delta.length;
      if (size == 0) continue;
      final next = total + size;
      positive(next, 'cumulativeLength');
      if (next <= total) {
        throw ArgumentError('Edge length is not representable in route scale');
      }
      edges.add(PolylineSegment._(start, end, total, size, delta.normalized));
      total = next;
    }
    if (edges.isEmpty) throw ArgumentError('A polyline needs a nonzero edge');
    segments = List.unmodifiable(edges);
    length = total;
  }

  /// Original immutable waypoint route; its capture behavior is unchanged.
  final SteeringPath route;

  /// Nondegenerate edges in traversal order, including the loop closing edge.
  late final List<PolylineSegment> segments;

  /// Positive total arc length.
  late final double length;

  /// Whether arc-distance sampling wraps around the closing edge.
  bool get loop => route.loop;

  /// Samples distance, clamped on open routes and wrapped on loops.
  /// Negative finite distances are allowed for sampling.
  Vec2 pointAt(double distance) {
    if (!distance.isFinite) throw ArgumentError.value(distance, 'distance');
    final arc = loop ? distance % length : distance.clamp(0.0, length);
    for (final segment in segments) {
      if (arc <= segment.startDistance + segment.length) {
        return segment.start +
            segment.direction * (arc - segment.startDistance);
      }
    }
    return segments.last.end;
  }

  /// Finds the nearest point within a nonnegative, ordered arc-distance range.
  /// Equal-distance ties preserve edge order. Bounds beyond length clamp to it.
  PathProjection project(Vec2 point,
      {double minDistance = 0, double? maxDistance}) {
    final maximum = maxDistance ?? length;
    nonNegative(minDistance, 'minDistance');
    nonNegative(maximum, 'maxDistance');
    if (maximum < minDistance) {
      throw ArgumentError('maxDistance must not precede minDistance');
    }
    final low = minDistance.clamp(0.0, length);
    final high = maximum.clamp(0.0, length);
    PathProjection? nearest;
    for (var i = 0; i < segments.length; i++) {
      final edge = segments[i];
      if (edge.startDistance > high || edge.startDistance + edge.length < low) {
        continue;
      }
      final start = (low - edge.startDistance).clamp(0.0, edge.length);
      final end = (high - edge.startDistance).clamp(0.0, edge.length);
      final local = (point - edge.start).dot(edge.direction).clamp(start, end);
      final projected = edge.start + edge.direction * local;
      final distance = (point - projected).length;
      if (nearest == null || distance < nearest.distanceFromPath) {
        nearest = PathProjection._(i, local / edge.length, projected,
            edge.startDistance + local, distance);
      }
    }
    return nearest!; // Nonempty geometry and a clamped nonempty range.
  }
}
