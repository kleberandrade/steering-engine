import 'package:steering_engine/steering_engine.dart';

void main() {
  final leader = SteeringAgent(position: Vec2(100, 0));
  final follow = LeaderFollowing(leader, distance: 40, avoidanceRadius: 12);
  var agent = SteeringAgent(position: Vec2.zero);
  for (var i = 0; i < 1800; i++) {
    agent = const SteeringEngine().step(agent, follow, 1 / 60);
  }
  if ((agent.position - follow.target).length > 1.1) {
    throw StateError('Leader arrival failed');
  }
  final blocker = SteeringAgent(position: Vec2(25, 0));
  final waiting = SteeringAgent(position: Vec2.zero);
  final queue = QueueFollowing(AgentNeighborhood.spatial([waiting, blocker]),
      movement: Seek(Vec2(200, 0)), spacing: 25);
  if (queue.calculate(waiting, 1 / 60) != Vec2.zero) {
    throw StateError('Queue failed to hold');
  }
  final wall =
      WallFollowing([WallSegment(Vec2.zero, Vec2(5000, 0))], wallOffset: 20);
  agent = SteeringAgent(position: Vec2(20, 50), velocity: Vec2(20, 0));
  for (var i = 0; i < 600; i++) {
    agent = const SteeringEngine().step(agent, wall, 1 / 60);
  }
  if ((agent.position.y - 20).abs() > 2) throw StateError('Wall offset failed');
  print(
      'Leader target: ${follow.target}; queue holds; wall position: ${agent.position}');
}
