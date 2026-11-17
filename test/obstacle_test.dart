import 'dart:math' as math;

import 'package:steering_engine/steering_engine.dart';
import 'package:test/test.dart';

void main() {
  final agent = SteeringAgent(
      position: Vec2.zero,
      velocity: Vec2(10, 0),
      maxSpeed: 20,
      maxAcceleration: 10);
  CircleObstacle circle(double x, double y, double r) =>
      CircleObstacle(Vec2(x, y), radius: r);
  ObstacleAvoidance avoiding(List<CircleObstacle> obstacles,
          {double scan = 100}) =>
      ObstacleAvoidance(obstacles,
          safetyMargin: 0, minLookAhead: scan, lookAheadTime: 0);

  test('inflated circle entry matches independent ray geometry', () {
    final obstacle = circle(50, 6, 10);
    final behavior = ObstacleAvoidance([obstacle],
        agentRadius: 2, safetyMargin: 3, minLookAhead: 100);
    final threat = behavior.findThreat(agent)!;
    // Inflated r=15, lateral=6, half-chord=sqrt(225-36).
    expect(threat.entryDistance, closeTo(50 - math.sqrt(189), 1e-9));
    expect(threat.expandedRadius, 15);
    expect(threat.isOverlapping, isFalse);
    expect(identical(threat.obstacle, obstacle), isTrue);
  });

  test('chooses earliest surface entry rather than nearest center', () {
    final nearCenter = circle(50, 0, 5); // entry 45
    final farCenter = circle(60, 0, 30); // entry 30
    final threat = avoiding([nearCenter, farCenter]).findThreat(agent)!;
    expect(identical(threat.obstacle, farCenter), isTrue);
    expect(threat.entryDistance, 30);
  });

  test('exact entry ties preserve obstacle input order', () {
    final first = circle(40, 6, 10);
    final second = circle(40, -6, 10);
    expect(
        identical(avoiding([first, second]).findThreat(agent)!.obstacle, first),
        isTrue);
  });

  test('ignores behind, lateral and beyond-horizon obstacles', () {
    final behavior =
        avoiding([circle(-30, 0, 5), circle(20, 11, 10), circle(120, 0, 10)]);
    expect(behavior.findThreat(agent), isNull);
    expect(behavior.calculate(agent, 0.1), Vec2.zero);
    expect(avoiding([]).calculate(agent, 1), Vec2.zero);
  });

  test('tangency and contact exactly at the scan end are included', () {
    expect(avoiding([circle(40, 10, 10)]).findThreat(agent)!.entryDistance, 40);
    expect(
        avoiding([circle(110, 0, 10)]).findThreat(agent)!.entryDistance, 100);
  });

  test('horizon grows with speed and remains at least the configured minimum',
      () {
    final behavior = ObstacleAvoidance([], lookAheadTime: 3, minLookAhead: 20);
    expect(behavior.scanDistance(agent), 30);
    expect(behavior.scanDistance(agent.copyWith(velocity: Vec2.zero)), 20);
  });

  test('steers opposite the obstacle lateral side with bounded braking', () {
    final below = avoiding([circle(40, 6, 10)]).calculate(agent, 0.1);
    final above = avoiding([circle(40, -6, 10)]).calculate(agent, 0.1);
    // normalize((-0.5,-1)) * 10, mirrored for the other side.
    expect(below.x, closeTo(-10 / math.sqrt(5), 1e-9));
    expect(below.y, closeTo(-20 / math.sqrt(5), 1e-9));
    expect(above.x, closeTo(below.x, 1e-9));
    expect(above.y, closeTo(-below.y, 1e-9));
    expect(below.length, lessThanOrEqualTo(10));
  });

  test('centerline tie is deterministic and zero braking is purely lateral',
      () {
    final behavior = ObstacleAvoidance([circle(40, 0, 10)],
        brakingWeight: 0, safetyMargin: 0, minLookAhead: 100);
    expect(behavior.calculate(agent, 0.1), Vec2(0, 10));
  });

  test('overlap escapes radially, including obstacles behind and zero speed',
      () {
    final behavior = avoiding([circle(-3, 4, 10)]);
    final threat = behavior.findThreat(agent)!;
    expect(threat.isOverlapping, isTrue);
    expect(threat.entryDistance, 0);
    final force = behavior.calculate(agent.copyWith(velocity: Vec2.zero), 0.1);
    expect(force.x, closeTo(6, 1e-9));
    expect(force.y, closeTo(-8, 1e-9));
    expect(avoiding([circle(0, 0, 10)]).calculate(agent, 0.1), Vec2(0, 10));
  });

  test('a stopped nonoverlapping agent does not invent a heading', () {
    expect(
        avoiding([circle(30, 0, 5)])
            .findThreat(agent.copyWith(velocity: Vec2.zero)),
        isNull);
  });

  test('zero acceleration emits zero; zero dt is pure', () {
    final behavior = avoiding([circle(30, 0, 5)]);
    expect(
        behavior.calculate(agent.copyWith(maxAcceleration: 0), 1), Vec2.zero);
    expect(behavior.calculate(agent, 0), behavior.calculate(agent, 1));
  });

  test('owns an immutable geometry list', () {
    final obstacles = [circle(30, 0, 5)];
    final behavior = avoiding(obstacles);
    obstacles.clear();
    expect(behavior.obstacles.length, 1);
    expect(() => behavior.obstacles.clear(), throwsUnsupportedError);
  });

  test('rotating the scenario rotates the predicted acceleration', () {
    final rotated = agent.copyWith(velocity: Vec2(0, 10));
    final a = avoiding([circle(40, 6, 10)]).calculate(agent, 1);
    final b = avoiding([circle(-6, 40, 10)]).calculate(rotated, 1);
    expect(b.x, closeTo(-a.y, 1e-9));
    expect(b.y, closeTo(a.x, 1e-9));
  });

  test('priority avoidance clears an obstacle and still reaches the target',
      () {
    final obstacle = circle(80, 0, 15);
    final avoidance = ObstacleAvoidance([obstacle],
        agentRadius: 5, safetyMargin: 4, minLookAhead: 45, lookAheadTime: 1.5);
    final steering =
        PrioritySteering([avoidance, Arrive(Vec2(180, 0), slowingRadius: 40)]);
    var current = SteeringAgent(
        position: Vec2.zero,
        velocity: Vec2(30, 0),
        maxSpeed: 50,
        maxAcceleration: 100);
    var minClearance = double.infinity;
    var activated = false;
    for (var i = 0; i < 1800; i++) {
      activated |= avoidance.findThreat(current) != null;
      final next = const SteeringEngine().step(current, steering, 1 / 60);
      // Independently measure the closest point on each swept integration segment.
      final delta = next.position - current.position;
      final from = current.position - obstacle.center;
      final denominator = delta.x * delta.x + delta.y * delta.y;
      final t = denominator == 0
          ? 0.0
          : (-(from.x * delta.x + from.y * delta.y) / denominator)
              .clamp(0.0, 1.0);
      final separation = (from + delta * t).length;
      minClearance = math.min(minClearance, separation - obstacle.radius - 5);
      current = next;
    }
    expect(activated, isTrue);
    expect(minClearance, greaterThan(0));
    expect((current.position - Vec2(180, 0)).length, lessThan(1.1));
    expect(current.velocity.length, lessThan(0.01));
  });

  test('rejects invalid configuration, elapsed time and derived overflow', () {
    for (final bad in [-1.0, double.nan, double.infinity]) {
      expect(() => CircleObstacle(Vec2.zero, radius: bad), throwsArgumentError);
      expect(
          () => ObstacleAvoidance([], agentRadius: bad), throwsArgumentError);
      expect(
          () => ObstacleAvoidance([], safetyMargin: bad), throwsArgumentError);
      expect(
          () => ObstacleAvoidance([], lookAheadTime: bad), throwsArgumentError);
      expect(
          () => ObstacleAvoidance([], minLookAhead: bad), throwsArgumentError);
      expect(
          () => ObstacleAvoidance([], brakingWeight: bad), throwsArgumentError);
      expect(() => avoiding([]).calculate(agent, bad), throwsArgumentError);
    }
    expect(() => CircleObstacle(Vec2.zero, radius: 0), throwsArgumentError);
    expect(() => ObstacleAvoidance([circle(0, 0, 1e308)], agentRadius: 1e308),
        throwsArgumentError);
    expect(
        () => ObstacleAvoidance([], lookAheadTime: 1e308).scanDistance(agent),
        throwsArgumentError);
    expect(() => avoiding([circle(-1.4e308, 9e307, 1.5e308)]).findThreat(agent),
        throwsArgumentError);
  });
}
