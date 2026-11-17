import 'package:steering_engine/steering_engine.dart';
import 'package:test/test.dart';

void main() {
  SteeringAgent at(double x, double y) => SteeringAgent(position: Vec2(x, y));

  test('routes copy inputs and reject empty collections', () {
    final points = [Vec2(10, 0), Vec2(20, 0)];
    final path = SteeringPath(points);
    points.clear();
    expect(path.waypoints.length, 2);
    expect(() => path.waypoints.clear(), throwsUnsupportedError);
    expect(() => SteeringPath([]), throwsArgumentError);
  });

  test('follows ordered capture regions and retains final target', () {
    final follower = FollowPath(
      SteeringPath([Vec2(10, 0), Vec2(30, 0), Vec2(30, 20)]),
      waypointRadius: 2,
    );
    follower.calculate(at(0, 0), 0.1);
    expect(follower.waypointIndex, 0);
    follower.calculate(at(8, 0), 0.1); // Inclusive capture boundary.
    expect(follower.waypointIndex, 1);
    follower.calculate(at(30, 0), 0.1);
    expect(follower.waypointIndex, 2);
    final result = follower.calculate(at(30, 20), 0.1);
    expect(follower.waypointIndex, 2);
    expect(result.length, 0);
    follower.reset();
    expect(follower.waypointIndex, 0);
  });

  test('positive dt loops from last to first', () {
    final follower = FollowPath(
      SteeringPath([Vec2(0, 0), Vec2(30, 0)], loop: true),
      waypointRadius: 2,
    );
    follower.calculate(at(0, 0), 0.1);
    expect(follower.waypointIndex, 1);
    follower.calculate(at(30, 0), 0.1);
    expect(follower.waypointIndex, 0);
  });

  test('overlapping loop points and single-point routes terminate safely', () {
    final follower = FollowPath(
      SteeringPath(List.filled(4, Vec2.zero), loop: true),
    );
    expect(follower.calculate(at(0, 0), 0.1).length, 0);
    expect(follower.waypointIndex, 3);
    final single = FollowPath(SteeringPath([Vec2.zero], loop: true));
    expect(single.calculate(at(0, 0), 0.1).length, 0);
    expect(single.waypointIndex, 0);
  });

  test('zero dt does not advance traversal even inside capture radius', () {
    final follower = FollowPath(SteeringPath([Vec2.zero, Vec2(100, 0)]));
    follower.calculate(at(0, 0), 0);
    expect(follower.waypointIndex, 0);
    const SteeringEngine().step(at(0, 0), follower, 0);
    expect(follower.waypointIndex, 0);
  });

  test('route configuration can be shared while traversal remains independent',
      () {
    final path = SteeringPath([Vec2.zero, Vec2(100, 0)]);
    final first = FollowPath(path);
    final second = FollowPath(path);
    first.calculate(at(0, 0), 0.1);
    expect(first.waypointIndex, 1);
    expect(second.waypointIndex, 0);
    expect(identical(first.path, second.path), isTrue);
  });

  test('final arrival applies independent expected deceleration', () {
    final follower = FollowPath(SteeringPath([Vec2(6, 0)]),
        waypointRadius: 2, slowingRadius: 11, stopRadius: 1, responseTime: 0.5);
    final agent = SteeringAgent(
        position: Vec2.zero,
        velocity: Vec2(2, 0),
        maxSpeed: 10,
        maxAcceleration: 100);
    // Desired speed 10 * (6-1)/(11-1) = 5. Acceleration (5-2)/0.5 = 6.
    final acceleration = follower.calculate(agent, 0.1);
    expect(acceleration.x, closeTo(6, 1e-9));
    expect(acceleration.y, 0);
  });

  test('traverses a right-angle route and settles at its final point', () {
    final path = SteeringPath([Vec2(80, 0), Vec2(80, 80), Vec2(160, 80)]);
    final follower = FollowPath(path, waypointRadius: 5, slowingRadius: 35);
    var agent =
        SteeringAgent(position: Vec2.zero, maxSpeed: 50, maxAcceleration: 100);
    final visited = <int>{};
    for (var frame = 0; frame < 1800; frame++) {
      agent = const SteeringEngine().step(agent, follower, 1 / 60);
      visited.add(follower.waypointIndex);
      expect(agent.velocity.length, lessThanOrEqualTo(50));
    }
    expect(visited, containsAll([0, 1, 2]));
    expect(follower.waypointIndex, 2);
    expect((agent.position - path.waypoints.last).length, lessThan(1.1));
    expect(agent.velocity.length, lessThan(0.01));
  });

  test('configuration and elapsed time reject invalid values', () {
    final path = SteeringPath([Vec2.zero]);
    for (final invalid in [-1.0, double.nan, double.infinity]) {
      expect(
          () => FollowPath(path, waypointRadius: invalid), throwsArgumentError);
      expect(
          () => FollowPath(path, slowingRadius: invalid), throwsArgumentError);
      expect(() => FollowPath(path, stopRadius: invalid), throwsArgumentError);
      expect(
          () => FollowPath(path, responseTime: invalid), throwsArgumentError);
      final follower = FollowPath(path);
      expect(() => follower.calculate(at(0, 0), invalid), throwsArgumentError);
      expect(follower.waypointIndex, 0);
    }
    expect(() => FollowPath(path, waypointRadius: 1, stopRadius: 1),
        throwsArgumentError);
    expect(() => FollowPath(path, slowingRadius: 1, stopRadius: 1),
        throwsArgumentError);
    expect(() => FollowPath(path, responseTime: 0), throwsArgumentError);
  });
}
