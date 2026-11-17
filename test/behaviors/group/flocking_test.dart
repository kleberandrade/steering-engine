import 'dart:math' as math;

import 'package:steering_engine/steering_engine.dart';
import 'package:test/test.dart';

void vector(Vec2 actual, double x, double y) {
  expect(actual.x, closeTo(x, 1e-9));
  expect(actual.y, closeTo(y, 1e-9));
}

void main() {
  SteeringAgent at(double x, double y, {Vec2 velocity = Vec2.zero}) =>
      SteeringAgent(
          position: Vec2(x, y),
          velocity: velocity,
          maxSpeed: 100,
          maxAcceleration: 100);
  final agent = SteeringAgent(
      position: Vec2.zero,
      velocity: Vec2(2, 0),
      maxSpeed: 10,
      maxAcceleration: 100);

  test('neighborhood freezes and deduplicates snapshots by identity', () {
    final other = at(3, 4);
    final coincident = at(0, 0);
    final source = [agent, other, other, coincident];
    final neighborhood = AgentNeighborhood(source);
    source.clear();
    expect(neighborhood.agents.length, 3);
    expect(neighborhood.neighborsFor(agent, radius: 5), [other, coincident]);
    expect(neighborhood.neighborsFor(agent, radius: 0), [coincident]);
    expect(() => neighborhood.agents.clear(), throwsUnsupportedError);
    expect(() => neighborhood.neighborsFor(agent, radius: 5).clear(),
        throwsUnsupportedError);
  });

  test('radius boundary is inclusive and observer itself is excluded', () {
    final boundary = at(6, 8);
    final outside = at(6, 8.01);
    final neighbors = AgentNeighborhood([agent, boundary, outside]);
    expect(neighbors.neighborsFor(agent, radius: 10), [boundary]);
  });

  test('separation follows independently calculated distance falloff', () {
    final separation =
        Separation(AgentNeighborhood([agent, at(3, 4)]), radius: 10);
    // Away=(-.6,-.8), falloff=1-5/10=.5, acceleration limit=100.
    vector(separation.calculate(agent, 1), -30, -40);
  });

  test('separation averages near and distant repulsion without normalization',
      () {
    final behavior =
        Separation(AgentNeighborhood([at(2, 0), at(0, 8)]), radius: 10);
    // Average of (-.8,0) and (0,-.2), times 100.
    vector(behavior.calculate(agent, 1), -40, -10);
  });

  test('symmetric, boundary and exact-overlap separation remain finite', () {
    vector(
        Separation(AgentNeighborhood([at(2, 0), at(-2, 0)]), radius: 10)
            .calculate(agent, 1),
        0,
        0);
    vector(
        Separation(AgentNeighborhood([at(10, 0)]), radius: 10)
            .calculate(agent, 1),
        0,
        0);
    vector(
        Separation(AgentNeighborhood([at(0, 0)]), radius: 10)
            .calculate(agent, 1),
        0,
        0);
  });

  test('alignment matches average neighbor velocity using response time', () {
    final behavior = Alignment(
        AgentNeighborhood([
          at(3, 4, velocity: Vec2(6, 4)),
          at(-3, 4, velocity: Vec2(2, 0)),
        ]),
        radius: 10,
        responseTime: 0.5);
    // Mean velocity=(4,2), current=(2,0): acceleration=(4,4).
    vector(behavior.calculate(agent, 1), 4, 4);
  });

  test('alignment caps desired speed and brakes toward stopped neighbors', () {
    vector(
        Alignment(AgentNeighborhood([at(1, 0, velocity: Vec2(100, 0))]),
                radius: 10, responseTime: 0.5)
            .calculate(agent, 1),
        16,
        0);
    vector(
        Alignment(AgentNeighborhood([at(1, 0)]), radius: 10, responseTime: 0.5)
            .calculate(agent, 1),
        -4,
        0);
  });

  test('cohesion is linear attraction toward the average neighbor offset', () {
    final behavior =
        Cohesion(AgentNeighborhood([at(6, 0), at(0, 8)]), radius: 10);
    // Mean offset=(3,4), divided by radius 10, times acceleration 100.
    vector(behavior.calculate(agent, 1), 30, 40);
  });

  test(
      'cohesion is invariant under translation and does not damp shared motion',
      () {
    final neighborhood = AgentNeighborhood([at(4, 0), at(-4, 0)]);
    vector(Cohesion(neighborhood, radius: 10).calculate(agent, 1), 0, 0);
    final translated = at(100, -20);
    vector(
        Cohesion(AgentNeighborhood([at(106, -20), at(100, -12)]), radius: 10)
            .calculate(translated, 1),
        30,
        40);
  });

  test('each group behavior coasts when the neighborhood is empty', () {
    final empty = AgentNeighborhood([agent]);
    for (final behavior in <SteeringBehavior>[
      Separation(empty),
      Alignment(empty),
      Cohesion(empty),
      Flocking(empty),
    ]) {
      expect(behavior.calculate(agent, 0), Vec2.zero);
      expect(behavior.calculate(agent, 1), Vec2.zero);
    }
  });

  test('flocking composes the three independently expected contributions', () {
    final neighborhood = AgentNeighborhood([at(3, 4, velocity: Vec2(6, 4))]);
    final flocking = Flocking(neighborhood,
        separationRadius: 10,
        neighborRadius: 10,
        responseTime: 0.5,
        separationWeight: 2,
        alignmentWeight: 1,
        cohesionWeight: 0.5);
    // 2*(-30,-40) + (8,8) + .5*(30,40).
    vector(flocking.calculate(agent, 1), -37, -52);
    expect(identical(flocking.neighborhood, neighborhood), isTrue);
    expect(flocking.separation.radius, 10);
    expect(flocking.alignment.radius, 10);
    expect(flocking.cohesion.radius, 10);
  });

  test(
      'flocking weights may disable rules and total acceleration remains bounded',
      () {
    final neighborhood = AgentNeighborhood([at(3, 4)]);
    vector(
        Flocking(neighborhood,
                separationRadius: 10,
                separationWeight: 1,
                alignmentWeight: 0,
                cohesionWeight: 0)
            .calculate(agent, 1),
        -30,
        -40);
    expect(
        Flocking(neighborhood,
                separationWeight: 0, alignmentWeight: 0, cohesionWeight: 0)
            .calculate(agent, 1),
        Vec2.zero);
    expect(
        Flocking(neighborhood,
                separationRadius: 10,
                separationWeight: 100,
                alignmentWeight: 0,
                cohesionWeight: 0)
            .calculate(agent, 1)
            .length,
        lessThanOrEqualTo(agent.maxAcceleration));
  });

  test('zero agent acceleration disables every component', () {
    final stopped = agent.copyWith(maxAcceleration: 0);
    final neighborhood = AgentNeighborhood([at(3, 4)]);
    for (final behavior in <SteeringBehavior>[
      Separation(neighborhood),
      Alignment(neighborhood),
      Cohesion(neighborhood),
      Flocking(neighborhood),
    ]) {
      expect(behavior.calculate(stopped, 1), Vec2.zero);
    }
  });

  test('synchronous pair matches the damped model and shared translation', () {
    var agents = [
      SteeringAgent(
          position: Vec2(-20, 0),
          velocity: Vec2(10, 0),
          maxSpeed: 30,
          maxAcceleration: 10),
      SteeringAgent(
          position: Vec2(20, 0),
          velocity: Vec2(10, 0),
          maxSpeed: 30,
          maxAcceleration: 10),
    ];
    for (var frame = 0; frame < 600; frame++) {
      final snapshot = AgentNeighborhood(agents);
      final behavior = Flocking(snapshot,
          separationRadius: 5,
          neighborRadius: 100,
          separationWeight: 1,
          responseTime: 0.5);
      agents = [
        for (final a in agents) const SteeringEngine().step(a, behavior, 1 / 60)
      ];
      for (final a in agents) {
        expect(a.velocity.length, lessThanOrEqualTo(30));
      }
    }
    final center = (agents[0].position + agents[1].position) / 2;
    vector(center, 100, 0);
    // Before separation activates, d'' + 4 d' + 0.2 d = 0 with d(0)=40,
    // d'(0)=0. Compare the discrete integrator to this independent solution.
    final slow = (-4 + math.sqrt(15.2)) / 2;
    final fast = (-4 - math.sqrt(15.2)) / 2;
    final expectedDistance = 40 *
        (-fast * math.exp(slow * 10) + slow * math.exp(fast * 10)) /
        (slow - fast);
    final expectedRelativeSpeed = (40 *
            slow *
            fast *
            (math.exp(fast * 10) - math.exp(slow * 10)) /
            (slow - fast))
        .abs();
    expect((agents[0].position - agents[1].position).length,
        closeTo(expectedDistance, 0.05));
    expect((agents[0].velocity - agents[1].velocity).length,
        closeTo(expectedRelativeSpeed, 0.01));
  });

  test(
      'frame results are independent of iteration order with one shared snapshot',
      () {
    final agents = [
      agent,
      at(3, 4, velocity: Vec2(6, 4)),
      at(-4, 2, velocity: Vec2(1, 3))
    ];
    final forward = Flocking(AgentNeighborhood(agents),
        separationRadius: 10, neighborRadius: 10);
    final reverse = Flocking(AgentNeighborhood(agents.reversed),
        separationRadius: 10, neighborRadius: 10);
    for (final a in agents) {
      final expected = const SteeringEngine().step(a, forward, 1 / 60);
      final actual = const SteeringEngine().step(a, reverse, 1 / 60);
      vector(actual.position, expected.position.x, expected.position.y);
      vector(actual.velocity, expected.velocity.x, expected.velocity.y);
    }
  });

  test('invalid distances, weights, response and elapsed time throw at runtime',
      () {
    final neighborhood = AgentNeighborhood([agent]);
    for (final invalid in [-1.0, double.nan, double.infinity]) {
      expect(() => neighborhood.neighborsFor(agent, radius: invalid),
          throwsArgumentError);
      expect(
          () => Separation(neighborhood, radius: invalid), throwsArgumentError);
      expect(
          () => Alignment(neighborhood, radius: invalid), throwsArgumentError);
      expect(
          () => Cohesion(neighborhood, radius: invalid), throwsArgumentError);
      expect(() => Flocking(neighborhood, separationWeight: invalid),
          throwsArgumentError);
      expect(() => Flocking(neighborhood, alignmentWeight: invalid),
          throwsArgumentError);
      expect(() => Flocking(neighborhood, cohesionWeight: invalid),
          throwsArgumentError);
      for (final behavior in <SteeringBehavior>[
        Separation(neighborhood),
        Alignment(neighborhood),
        Cohesion(neighborhood),
        Flocking(neighborhood),
      ]) {
        expect(() => behavior.calculate(agent, invalid), throwsArgumentError);
      }
    }
    expect(() => Separation(neighborhood, radius: 0), throwsArgumentError);
    expect(() => Alignment(neighborhood, radius: 0), throwsArgumentError);
    expect(() => Cohesion(neighborhood, radius: 0), throwsArgumentError);
    expect(() => Alignment(neighborhood, responseTime: 0), throwsArgumentError);
    expect(
        () => Flocking(neighborhood, separationRadius: 0), throwsArgumentError);
    expect(
        () => Flocking(neighborhood, neighborRadius: 0), throwsArgumentError);
    expect(() => Flocking(neighborhood, responseTime: 0), throwsArgumentError);
  });
}
