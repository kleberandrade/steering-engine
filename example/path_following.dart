import 'package:steering_engine/steering_engine.dart';

void main() {
  final path = SteeringPath([Vec2(80, 0), Vec2(80, 80), Vec2(160, 80)]);
  final follower = FollowPath(path, waypointRadius: 5, slowingRadius: 35);
  var agent = SteeringAgent(
    position: Vec2.zero,
    maxSpeed: 50,
    maxAcceleration: 100,
  );
  for (var frame = 0; frame < 1800; frame++) {
    agent = const SteeringEngine().step(agent, follower, 1 / 60);
  }
  print('Waypoint: ${follower.waypointIndex + 1}/${path.waypoints.length}');
  print('Position: ${agent.position}');
  if (follower.waypointIndex != 2 ||
      (agent.position - path.waypoints.last).length > 1.1) {
    throw StateError('The route was not completed');
  }
}
