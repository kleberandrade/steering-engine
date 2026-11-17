import 'package:steering_engine/steering_engine.dart';

({double peakCornerSpeed, double maxError, double finalDistance}) simulate(
    PolylinePath path, double cornerPreview) {
  final follower = FollowPolyline(path,
      lookAheadDistance: 15,
      searchDistance: 40,
      cornerSlowingDistance: cornerPreview,
      slowingRadius: 35);
  var agent =
      SteeringAgent(position: Vec2.zero, maxSpeed: 40, maxAcceleration: 100);
  var peakCornerSpeed = 0.0;
  var maxError = 0.0;
  for (var frame = 0; frame < 2400; frame++) {
    agent = const SteeringEngine().step(agent, follower, 1 / 60);
    final error = path.project(agent.position).distanceFromPath;
    if (error > maxError) maxError = error;
    if ((agent.position - Vec2(100, 0)).length < 20 &&
        agent.velocity.length > peakCornerSpeed) {
      peakCornerSpeed = agent.velocity.length;
    }
  }
  return (
    peakCornerSpeed: peakCornerSpeed,
    maxError: maxError,
    finalDistance: (agent.position - Vec2(100, 100)).length
  );
}

void main() {
  final path =
      PolylinePath(SteeringPath([Vec2.zero, Vec2(100, 0), Vec2(100, 100)]));
  final projection = path.project(Vec2(60, 20));
  if (projection.distanceAlong != 60 ||
      path.pointAt(projection.distanceAlong + 60) != Vec2(100, 20)) {
    throw StateError('Independent L-route geometry failed');
  }
  final plain = simulate(path, 0);
  final preview = simulate(path, 35);
  if (preview.peakCornerSpeed >= plain.peakCornerSpeed ||
      preview.finalDistance > 1.1 ||
      plain.finalDistance > 1.1) {
    throw StateError('Corner preview or final arrival regression');
  }
  print('No corner cap: $plain');
  print('35-unit corner preview: $preview');
  print('Fixture: L-route 100+100, dt=1/60, 2400 frames, V=40, A=100.');
  print('Corner metric: peak speed within 20 units of (100,0).');
}
