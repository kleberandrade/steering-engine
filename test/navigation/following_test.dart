import 'package:steering_engine/steering_engine.dart';
import 'package:test/test.dart';

void main() {
  SteeringAgent at(double x, double y, {Vec2 velocity = Vec2.zero}) =>
      SteeringAgent(
          position: Vec2(x, y),
          velocity: velocity,
          maxSpeed: 100,
          maxAcceleration: 100);
  test('dot product and wall projection have independently calculated results',
      () {
    expect(Vec2(3, 4).dot(Vec2(1, -2)), -5);
    expect(() => Vec2(1e200, 0).dot(Vec2(1e200, 0)), throwsArgumentError);
    final wall = WallSegment(Vec2(0, 0), Vec2(100, 0));
    expect(wall.closestPoint(Vec2(30, 20)), Vec2(30, 0));
    expect(wall.closestPoint(Vec2(-10, 20)), Vec2.zero);
    expect(wall.closestPoint(Vec2(120, 20)), Vec2(100, 0));
    expect(() => WallSegment(Vec2.zero, Vec2.zero), throwsArgumentError);
  });
  test(
      'leader trailing target rotates with heading and supports stationary leaders',
      () {
    final leader = at(100, 100, velocity: Vec2(0, 10));
    final follow = LeaderFollowing(leader, distance: 40, avoidanceRadius: 10);
    expect(follow.target, Vec2(100, 60));
    expect(
        LeaderFollowing(at(100, 100),
                distance: 40,
                avoidanceRadius: 10,
                fallbackDirection: Vec2(0, 1))
            .target,
        Vec2(100, 60));
    expect(follow.calculate(leader, .1), Vec2.zero);
    final result = follow.calculate(at(100, 0), .1);
    expect(result.y, greaterThan(0));
    expect(result.length, lessThanOrEqualTo(100));
  });
  test(
      'leader clearance requests escape and follower converges behind stopped leader',
      () {
    final follow =
        LeaderFollowing(at(100, 0), distance: 40, avoidanceRadius: 12);
    expect(follow.calculate(at(98, 2), .1).y, greaterThan(0));
    var agent = at(0, 0);
    for (var i = 0; i < 1800; i++) {
      agent = const SteeringEngine().step(agent, follow, 1 / 60);
    }
    expect((agent.position - Vec2(60, 0)).length, lessThan(1.1));
  });
  test('queue limits forward motion at spacing and resumes when blocker leaves',
      () {
    final observer = at(0, 0);
    final blocker = at(25, 0);
    final movement = Seek(Vec2(200, 0));
    final queued = QueueFollowing(AgentNeighborhood([observer, blocker]),
        movement: movement, direction: Vec2(1, 0), spacing: 25);
    expect(identical(queued.findBlocker(observer), blocker), isTrue);
    expect(queued.calculate(observer, .1), Vec2.zero);
    final released = QueueFollowing(AgentNeighborhood([observer]),
        movement: movement, direction: Vec2(1, 0));
    expect(released.calculate(observer, .1).x, greaterThan(0));
  });
  test(
      'queue chooses nearest forward lane occupant and retains lateral steering',
      () {
    final agent = at(0, 0, velocity: Vec2(20, 0));
    final near = at(30, 2);
    final neighbors =
        AgentNeighborhood([agent, at(-5, 0), at(15, 40), at(60, 0), near]);
    final queue = QueueFollowing(neighbors,
        movement: Seek(Vec2(200, 200)),
        direction: Vec2(1, 0),
        spacing: 25,
        laneRadius: 10,
        responseTime: .5);
    expect(identical(queue.findBlocker(agent), near), isTrue);
    final force = queue.calculate(agent, .1);
    // Allowed speed=(30-25)/.5=10; acceleration cap=(10-20)/.5=-20.
    expect(force.x, closeTo(-20, 1e-9));
    expect(force.y, greaterThan(0));
    expect(force.length, lessThanOrEqualTo(100));
  });
  test('stationary queue holds position for repeated frames without creeping',
      () {
    var agent = at(0, 0);
    final blocker = at(25, 0);
    for (var i = 0; i < 300; i++) {
      final queue = QueueFollowing(AgentNeighborhood([agent, blocker]),
          movement: Seek(Vec2(200, 0)), spacing: 25);
      agent = const SteeringEngine().step(agent, queue, 1 / 60);
    }
    expect(agent.position, Vec2.zero);
  });
  test('wall following predicts the offset target on either side', () {
    final wall = WallSegment(Vec2(0, 0), Vec2(1000, 0));
    final agent = at(100, 10, velocity: Vec2(20, 0));
    final left = WallFollowing([wall], wallOffset: 20, lookAhead: 30);
    expect(left.targetFor(agent), Vec2(160, 20));
    final right = WallFollowing([wall],
        wallOffset: 20, lookAhead: 30, side: WallSide.right);
    expect(right.targetFor(agent), Vec2(160, -20));
    final far = at(100, 500, velocity: Vec2(20, 0));
    expect(left.targetFor(far), isNull);
    expect(left.calculate(far, 1), Vec2.zero);
    expect(WallFollowing([]).calculate(agent, 1), Vec2.zero);
  });
  test('wall follower travels along a wall and approaches its offset', () {
    var agent = at(20, 50, velocity: Vec2(20, 0));
    final rule = WallFollowing([WallSegment(Vec2.zero, Vec2(5000, 0))],
        wallOffset: 20, lookAhead: 30, maxDistance: 100);
    for (var i = 0; i < 600; i++) {
      agent = const SteeringEngine().step(agent, rule, 1 / 60);
    }
    expect(agent.position.x, greaterThan(500));
    expect(agent.position.y, closeTo(20, 2));
  });
  test('following inputs are validated independently of assertions', () {
    final leader = at(100, 0);
    final wall = WallSegment(Vec2.zero, Vec2(100, 0));
    for (final bad in [-1.0, double.nan, double.infinity]) {
      expect(() => LeaderFollowing(leader, distance: bad), throwsArgumentError);
      expect(() => LeaderFollowing(leader, avoidanceRadius: bad),
          throwsArgumentError);
      expect(
          () => QueueFollowing(AgentNeighborhood([]),
              movement: Brake(), spacing: bad),
          throwsArgumentError);
      expect(
          () => QueueFollowing(AgentNeighborhood([]),
              movement: Brake(), lookAhead: bad),
          throwsArgumentError);
      expect(() => WallFollowing([wall], wallOffset: bad), throwsArgumentError);
      for (final behavior in <SteeringBehavior>[
        LeaderFollowing(leader),
        QueueFollowing(AgentNeighborhood([]), movement: Brake()),
        WallFollowing([wall])
      ]) {
        expect(() => behavior.calculate(leader, bad), throwsArgumentError);
      }
    }
    expect(() => LeaderFollowing(leader, distance: 10, avoidanceRadius: 20),
        throwsArgumentError);
    expect(
        () => QueueFollowing(AgentNeighborhood([]),
            movement: Brake(), direction: Vec2.zero),
        throwsArgumentError);
    expect(() => WallFollowing([wall], lookAhead: 0), throwsArgumentError);
    expect(() => LeaderFollowing(leader, responseTime: 0), throwsArgumentError);
    expect(() => LeaderFollowing(leader, fallbackDirection: Vec2.zero),
        throwsArgumentError);
    expect(
        () => QueueFollowing(AgentNeighborhood([]),
            movement: Brake(), responseTime: 0),
        throwsArgumentError);
    expect(
        () => QueueFollowing(AgentNeighborhood([]),
            movement: Brake(), laneRadius: 0),
        throwsArgumentError);
    expect(() => WallFollowing([wall], maxDistance: 0), throwsArgumentError);
    expect(() => WallFollowing([wall], responseTime: 0), throwsArgumentError);
  });
}
