import 'dart:math' as math;
import 'package:steering_engine/steering_engine.dart';
import 'package:test/test.dart';

void main() {
  test('spatial queries preserve identity, order and inclusive boundaries', () {
    final self = SteeringAgent(position: Vec2(-10, -10));
    final agents = [
      self,
      SteeringAgent(position: Vec2(-13, -14)),
      SteeringAgent(position: Vec2(-10, -10)),
      SteeringAgent(position: Vec2(10, 10))
    ];
    final linear = AgentNeighborhood([...agents, agents[1]]);
    final grid = AgentNeighborhood.spatial([...agents, agents[1]], cellSize: 5);
    expect(grid.usesSpatialIndex, isTrue);
    for (final radius in [0.0, 5.0, 100.0]) {
      expect(grid.neighborsFor(self, radius: radius),
          linear.neighborsFor(self, radius: radius));
    }
  });
  test('seeded random scenes match the linear oracle for every observer', () {
    final random = math.Random(891);
    final agents = List.generate(
        180,
        (_) => SteeringAgent(
            position: Vec2(random.nextDouble() * 1000 - 500,
                random.nextDouble() * 1000 - 500),
            velocity: Vec2(
                random.nextDouble() * 20 - 10, random.nextDouble() * 20 - 10)));
    final linear = AgentNeighborhood(agents);
    for (final size in [7.0, 80.0, 300.0]) {
      final grid = AgentNeighborhood.spatial(agents, cellSize: size);
      for (final agent in agents) {
        for (final radius in [0.0, 7.0, 80.0, 10000.0]) {
          expect(grid.neighborsFor(agent, radius: radius),
              linear.neighborsFor(agent, radius: radius));
        }
        final a = Flocking(linear).calculate(agent, 1 / 60);
        final b = Flocking(grid).calculate(agent, 1 / 60);
        expect(b.x, a.x);
        expect(b.y, a.y);
      }
    }
  });
  test('unsafe cell coordinates fall back to the linear query', () {
    final a = SteeringAgent(position: Vec2(1e100, 0));
    final b = SteeringAgent(position: Vec2(1e100, 1));
    final grid = AgentNeighborhood.spatial([a, b], cellSize: 1e-100);
    expect(grid.usesSpatialIndex, isFalse);
    expect(grid.neighborsFor(a, radius: 2), [b]);
    final normal = AgentNeighborhood.spatial([a.copyWith(position: Vec2.zero)],
        cellSize: 10);
    expect(normal.neighborsFor(a, radius: 1e200).length, 1);
  });
  test('spatial snapshot owns its list and rejects invalid tuning', () {
    final agents = [SteeringAgent(position: Vec2.zero)];
    final grid = AgentNeighborhood.spatial(agents);
    agents.clear();
    expect(grid.agents.length, 1);
    expect(() => grid.agents.clear(), throwsUnsupportedError);
    for (final bad in [0.0, -1.0, double.nan, double.infinity]) {
      expect(() => AgentNeighborhood.spatial([], cellSize: bad),
          throwsArgumentError);
    }
    expect(() => grid.neighborsFor(grid.agents.first, radius: -1),
        throwsArgumentError);
  });
}
