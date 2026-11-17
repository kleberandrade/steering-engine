import 'package:steering_engine/steering_engine.dart';

void main() {
  var agent = SteeringAgent(position: Vec2.zero);
  final behavior = WeightedBlend([
    WeightedBehavior(Seek(Vec2(200, 0)), weight: 0.8),
    WeightedBehavior(Flee(Vec2(0, 100)), weight: 0.2),
  ]);
  for (var frame = 0; frame < 60; frame++) {
    agent = const SteeringEngine().step(agent, behavior, 1 / 60);
  }
  print('Blended motion: ${agent.position}');
  final priority = PrioritySteering([
    Flee(agent.position + Vec2(20, 0)),
    Seek(Vec2(200, 0)),
  ]);
  print('First active acceleration: ${priority.calculate(agent, 1 / 60)}');
}
