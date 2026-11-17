import 'dart:math' as math;

import 'package:steering_engine/steering_engine.dart';

void main() {
  final obstacles = [
    CircleObstacle(Vec2(480, 300), radius: 60),
    CircleObstacle(Vec2(700, 450), radius: 45),
    CircleObstacle(Vec2(720, 100), radius: 40),
  ];
  final avoidance = ObstacleAvoidance(obstacles,
      agentRadius: 18, safetyMargin: 10, minLookAhead: 90, lookAheadTime: 1.2);
  final target = Vec2(730, 280);
  final steering = PrioritySteering([
    avoidance,
    Arrive(target, slowingRadius: 150),
  ]);
  var agent = SteeringAgent(
      position: Vec2(260, 340),
      velocity: Vec2(35, 0),
      maxSpeed: 140,
      maxAcceleration: 220);
  var clearance = double.infinity;
  for (var frame = 0; frame < 2400; frame++) {
    final next = const SteeringEngine().step(agent, steering, 1 / 60);
    final segment = next.position - agent.position;
    final squared = segment.x * segment.x + segment.y * segment.y;
    for (final obstacle in obstacles) {
      final from = agent.position - obstacle.center;
      final t = squared == 0
          ? 0.0
          : (-(from.x * segment.x + from.y * segment.y) / squared)
              .clamp(0.0, 1.0);
      clearance = math.min(
          clearance,
          (from + segment * t).length -
              obstacle.radius -
              avoidance.agentRadius);
    }
    agent = next;
  }
  print('Position: ${agent.position}');
  print('Minimum swept physical clearance: ${clearance.toStringAsFixed(2)}');
  if (clearance <= 0 || (agent.position - target).length > 1.1) {
    throw StateError('This example did not clear the obstacles and arrive');
  }
}
