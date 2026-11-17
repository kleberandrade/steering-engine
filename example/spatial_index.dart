import 'package:steering_engine/steering_engine.dart';

void main() {
  final agents = List.generate(200,
      (i) => SteeringAgent(position: Vec2((i % 20) * 20.0, (i ~/ 20) * 20.0)));
  final linear = AgentNeighborhood(agents);
  final spatial = AgentNeighborhood.spatial(agents, cellSize: 80);
  for (final agent in agents) {
    final expected = linear.neighborsFor(agent, radius: 80);
    final actual = spatial.neighborsFor(agent, radius: 80);
    if (expected.length != actual.length) {
      throw StateError('Neighbor count differs');
    }
    for (var i = 0; i < expected.length; i++) {
      if (!identical(expected[i], actual[i])) {
        throw StateError('Neighbor order differs');
      }
    }
    final a = Flocking(linear).calculate(agent, 1 / 60);
    final b = Flocking(spatial).calculate(agent, 1 / 60);
    if (a != b) throw StateError('Flocking result differs');
  }
  print('Spatial and linear results match for ${agents.length} observers.');
}
