import 'package:steering_engine/steering_engine.dart';

void main() {
  const engine = SteeringEngine();
  var agent =
      SteeringAgent(position: Vec2.zero, maxSpeed: 80, maxAcceleration: 160);
  final behavior = Arrive(Vec2(200, 100), slowingRadius: 80);
  for (var frame = 0; frame < 600; frame++) {
    agent = engine.step(agent, behavior, 1 / 60);
  }
  print('Position: ${agent.position}');
  print('Speed: ${agent.velocity.length.toStringAsFixed(3)}');
  if ((agent.position - behavior.target).length > 2) {
    throw StateError('Agent did not reach the arrival region');
  }
}
