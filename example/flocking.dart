import 'dart:math' as math;

import 'package:steering_engine/steering_engine.dart';

void main() {
  final random = math.Random(42);
  var agents = List.generate(24, (i) {
    final angle = random.nextDouble() * 2 * math.pi;
    return SteeringAgent(
      position: Vec2((i % 6) * 20.0, (i ~/ 6) * 20.0),
      velocity: Vec2(math.cos(angle), math.sin(angle)) * 20,
      maxSpeed: 50,
      maxAcceleration: 60,
    );
  });
  final target = Vec2(400, 200);
  for (var frame = 0; frame < 1200; frame++) {
    // One immutable observation for all agents, then replace the entire frame.
    final snapshot = AgentNeighborhood(agents);
    final steering = WeightedBlend([
      WeightedBehavior(Flocking(snapshot,
          separationRadius: 24, neighborRadius: 90, cohesionWeight: 0.7)),
      WeightedBehavior(Arrive(target, slowingRadius: 100), weight: 0.2),
    ]);
    agents = [
      for (final agent in agents)
        const SteeringEngine().step(agent, steering, 1 / 60),
    ];
  }
  var center = Vec2.zero;
  for (final agent in agents) {
    center = center + agent.position / agents.length.toDouble();
    if (agent.velocity.length > agent.maxSpeed) {
      throw StateError('A flock agent exceeded its speed limit');
    }
  }
  print('Agents: ${agents.length}');
  print('Center after 20 simulated seconds: $center');
  if (center.x <= 100) {
    throw StateError('The flock did not advance toward the goal');
  }
}
