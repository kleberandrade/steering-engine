import 'dart:math' as math;
import '../core/agent.dart';
import '../core/steering_behavior.dart';
import '../core/validation.dart';
import '../math/vec2.dart';
import 'polyline_path.dart';

/// Stateful continuous guidance along finite polyline edges.
///
/// Own one instance per follower. First acquisition is global; subsequent
/// projections use a forward arc window and monotonic unwrapped progress.
/// Call [reacquire] after teleports or large deviations. Corner preview caps
/// desired speed heuristically; it does not enforce curvature or prevent contact.
final class FollowPolyline implements SteeringBehavior {
  /// Creates a follower. All lengths use the agent's distance units.
  FollowPolyline(this.path,
      {this.lookAheadDistance = 30,
      this.predictionTime = .2,
      this.searchDistance = 80,
      this.cornerSlowingDistance = 40,
      this.minCornerSpeedRatio = .35,
      this.slowingRadius = 50,
      this.stopRadius = 1,
      this.responseTime = .25}) {
    positive(lookAheadDistance, 'lookAheadDistance');
    nonNegative(predictionTime, 'predictionTime');
    positive(searchDistance, 'searchDistance');
    nonNegative(cornerSlowingDistance, 'cornerSlowingDistance');
    nonNegative(minCornerSpeedRatio, 'minCornerSpeedRatio');
    if (minCornerSpeedRatio > 1) {
      throw ArgumentError('minCornerSpeedRatio must not exceed one');
    }
    nonNegative(stopRadius, 'stopRadius');
    positive(slowingRadius, 'slowingRadius');
    positive(responseTime, 'responseTime');
    if (slowingRadius <= stopRadius) {
      throw ArgumentError('slowingRadius must exceed stopRadius');
    }
    reset();
  }

  /// Shared immutable arc-length geometry.
  final PolylinePath path;

  /// Target distance forward from the projected progress; positive.
  final double lookAheadDistance;

  /// Time in seconds used to predict the position being projected.
  final double predictionTime;

  /// Forward projection window after first acquisition; positive.
  final double searchDistance;

  /// Forward corner-preview range; zero disables corner speed reduction.
  final double cornerSlowingDistance;

  /// Sharp reversal's desired-speed ratio, in [0,1]; straight edges retain one.
  final double minCornerSpeedRatio;

  /// Final-point arrival radius, greater than [stopRadius].
  final double slowingRadius;

  /// Radius inside which final-point desired speed is zero.
  final double stopRadius;

  /// Positive velocity response time in seconds.
  final double responseTime;

  double _progress = 0;
  PathProjection? _projection;
  late Vec2 _target;
  double _desiredSpeed = 0;

  /// Monotonic route distance; loops accumulate full laps without wrapping.
  double get progress => _progress;

  /// Completed laps since reset or explicit global reacquisition.
  int get lapCount => path.loop ? (_progress / path.length).floor() : 0;

  /// Last target, readable without advancing the follower.
  Vec2 get currentTarget => _target;

  /// Last projection; null before acquisition. Its arc distance is lap-local.
  PathProjection? get lastProjection => _projection;

  /// Last requested speed before velocity correction; not measured actual speed.
  double get lastDesiredSpeed => _desiredSpeed;

  /// Clears traversal state. The next positive-dt calculation acquires globally.
  void reset() {
    _progress = 0;
    _projection = null;
    _target = path.pointAt(lookAheadDistance);
    _desiredSpeed = 0;
  }

  /// Globally projects the agent's actual position, resets lap count, and updates
  /// the target. Use explicitly after teleports; velocity prediction is omitted.
  void reacquire(SteeringAgent agent) {
    _projection = path.project(agent.position);
    _progress = _projection!.distanceAlong;
    _target = path.pointAt(_progress + lookAheadDistance);
    _desiredSpeed = 0;
  }

  ({PathProjection projection, double progress}) _project(Vec2 predicted) {
    if (_projection == null) {
      final result = path.project(predicted);
      return (projection: result, progress: result.distanceAlong);
    }
    if (!path.loop) {
      final result = path.project(predicted,
          minDistance: _progress, maxDistance: _progress + searchDistance);
      return (projection: result, progress: result.distanceAlong);
    }
    final local = _progress % path.length;
    final lapStart = _progress - local;
    final window = math.min(searchDistance, path.length);
    final first = path.project(predicted,
        minDistance: local, maxDistance: math.min(path.length, local + window));
    var result = (projection: first, progress: lapStart + first.distanceAlong);
    if (local + window >= path.length) {
      final wrapped =
          path.project(predicted, maxDistance: local + window - path.length);
      if (wrapped.distanceFromPath < first.distanceFromPath) {
        result = (
          projection: wrapped,
          progress: lapStart + path.length + wrapped.distanceAlong
        );
      }
    }
    return result;
  }

  double _cornerSpeed(double maximum) {
    if (cornerSlowingDistance == 0) return maximum;
    var ratio = 1.0;
    final local = path.loop ? _progress % path.length : _progress;
    for (var i = 0; i < path.segments.length; i++) {
      if (!path.loop && i == path.segments.length - 1) break;
      final edge = path.segments[i];
      var distance = edge.startDistance + edge.length - local;
      if (distance < 0 && path.loop) distance += path.length;
      if (distance < 0 || distance > cornerSlowingDistance) continue;
      final next = path.segments[(i + 1) % path.segments.length];
      final cosine = edge.direction.dot(next.direction).clamp(-1.0, 1.0);
      final corner =
          minCornerSpeedRatio + (1 - minCornerSpeedRatio) * (1 + cosine) / 2;
      ratio = math.min(
          ratio, corner + (1 - corner) * distance / cornerSlowingDistance);
    }
    return maximum * ratio;
  }

  @override
  Vec2 calculate(SteeringAgent agent, double dt) {
    nonNegative(dt, 'dt');
    if (dt == 0) return Vec2.zero;
    final predicted = agent.position + agent.velocity * predictionTime;
    final observation = _project(predicted);
    final targetDistance = observation.progress + lookAheadDistance;
    nonNegative(targetDistance, 'targetDistance');
    _projection = observation.projection;
    _progress = observation.progress;
    _target = path.pointAt(targetDistance);
    var speed = _cornerSpeed(agent.maxSpeed);
    final offset = _target - agent.position;
    if (!path.loop && targetDistance >= path.length) {
      final fraction =
          ((offset.length - stopRadius) / (slowingRadius - stopRadius))
              .clamp(0.0, 1.0);
      speed = math.min(speed, agent.maxSpeed * fraction);
    }
    _desiredSpeed = speed;
    final desired = offset.normalized * speed;
    return ((desired - agent.velocity) / responseTime)
        .limited(agent.maxAcceleration);
  }
}
