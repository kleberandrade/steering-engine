import 'package:steering_engine/steering_engine.dart';
import 'package:test/test.dart';

PolylinePath elbow({bool loop = false}) => PolylinePath(
    SteeringPath([Vec2.zero, Vec2(100, 0), Vec2(100, 100)], loop: loop));
SteeringAgent at(double x, double y, {Vec2? velocity}) => SteeringAgent(
    position: Vec2(x, y),
    velocity: velocity ?? Vec2.zero,
    maxSpeed: 10,
    maxAcceleration: 100);

void main() {
  test(
      'finite projections, fractions and arc distance match independent geometry',
      () {
    final path = elbow();
    final p = path.project(Vec2(30, 20));
    expect(p.point, Vec2(30, 0));
    expect(p.segmentIndex, 0);
    expect(p.fraction, closeTo(.3, 1e-12));
    expect(p.distanceAlong, 30);
    expect(p.distanceFromPath, 20);
    expect(path.project(Vec2(-10, 5)).point, Vec2.zero);
    expect(path.project(Vec2(120, 130)).point, Vec2(100, 100));
    expect(path.pointAt(120), Vec2(100, 20));
    expect(path.pointAt(-5), Vec2.zero);
    expect(path.pointAt(500), Vec2(100, 100));
  });
  test('arc-range projection cannot jump to a distant route branch', () {
    final path = elbow();
    final p = path.project(Vec2(100, 90), minDistance: 30, maxDistance: 60);
    expect(p.point, Vec2(60, 0));
    expect(p.distanceAlong, 60);
    expect(() => path.project(Vec2.zero, minDistance: 40, maxDistance: 30),
        throwsArgumentError);
  });
  test(
      'duplicate vertices are skipped; immutable geometry and degeneracy are explicit',
      () {
    final path = PolylinePath(
        SteeringPath([Vec2.zero, Vec2.zero, Vec2(10, 0), Vec2(10, 0)]));
    expect(path.length, 10);
    expect(path.segments.length, 1);
    expect(() => path.segments.clear(), throwsUnsupportedError);
    expect(() => PolylinePath(SteeringPath([Vec2.zero])), throwsArgumentError);
    expect(() => PolylinePath(SteeringPath([Vec2.zero, Vec2.zero], loop: true)),
        throwsArgumentError);
  });
  test(
      'loop sampling wraps positive and negative arc distances through closing edge',
      () {
    final path =
        PolylinePath(SteeringPath([Vec2.zero, Vec2(10, 0)], loop: true));
    expect(path.length, 20);
    expect(path.pointAt(15), Vec2(5, 0));
    expect(path.pointAt(25), Vec2(5, 0));
    expect(path.pointAt(-5), Vec2(5, 0));
  });
  test('target advances through a corner by arc length, not a capture radius',
      () {
    final rule =
        FollowPolyline(elbow(), predictionTime: 0, lookAheadDistance: 60);
    rule.calculate(at(60, 20), .1);
    expect(rule.progress, 60);
    expect(rule.currentTarget, Vec2(100, 20));
    expect(rule.lastProjection!.point, Vec2(60, 0));
  });
  test(
      'prediction uses velocity and zero dt leaves all follower state untouched',
      () {
    final rule =
        FollowPolyline(elbow(), predictionTime: .5, lookAheadDistance: 10);
    final agent = at(20, 0, velocity: Vec2(10, 0));
    rule.calculate(agent, 0);
    expect(rule.progress, 0);
    expect(rule.lastProjection, isNull);
    expect(
        identical(const SteeringEngine().step(agent, rule, 0), agent), isTrue);
    rule.calculate(agent, .1);
    expect(rule.progress, 25);
    expect(rule.currentTarget, Vec2(35, 0));
  });
  test('normal following is monotonic and global reacquisition is explicit',
      () {
    final rule = FollowPolyline(elbow(), predictionTime: 0, searchDistance: 20);
    rule.calculate(at(10, 0), .1);
    rule.calculate(at(100, 90), .1);
    expect(rule.progress, 30); // window [10,30], not the distant second segment
    rule.calculate(at(0, 0), .1);
    expect(rule.progress, 30);
    rule.reacquire(at(100, 90));
    expect(rule.progress, 190);
    rule.reset();
    expect(rule.progress, 0);
    expect(rule.lastProjection, isNull);
    rule.calculate(at(80, 0), .1);
    expect(rule.progress, 80); // fresh global acquisition
  });
  test(
      'crossing branch outside the progress window is not reacquired implicitly',
      () {
    final path = PolylinePath(
        SteeringPath([Vec2(0, 0), Vec2(100, 100), Vec2(0, 100), Vec2(100, 0)]));
    final rule = FollowPolyline(path, predictionTime: 0, searchDistance: 20);
    rule.calculate(at(40, 40), .1);
    rule.calculate(at(51, 49), .1);
    expect(rule.lastProjection!.segmentIndex, 0);
  });
  test('loop progress crosses the closing edge and retains lap count', () {
    final path =
        PolylinePath(SteeringPath([Vec2.zero, Vec2(10, 0)], loop: true));
    final rule = FollowPolyline(path,
        predictionTime: 0, searchDistance: 5, lookAheadDistance: 2);
    rule.reacquire(at(2, 0));
    for (final point in [
      at(6, 0),
      at(10, 0),
      at(6, 0),
      at(2, 0),
      at(0, 0),
      at(3, 0)
    ]) {
      rule.calculate(point, .1);
    }
    expect(rule.progress, 23);
    expect(rule.lapCount, 1);
    expect(rule.currentTarget, Vec2(5, 0));
  });
  test('two followers share geometry but retain independent progress', () {
    final path = elbow();
    final a = FollowPolyline(path, predictionTime: 0);
    final b = FollowPolyline(path, predictionTime: 0);
    a.calculate(at(70, 0), .1);
    expect(a.progress, 70);
    expect(b.progress, 0);
    expect(identical(a.path, b.path), isTrue);
  });

  test('priority skips do not advance traversal state', () {
    final rule = FollowPolyline(elbow(), predictionTime: 0);
    final agent = at(20, 0);
    rule.calculate(agent, .1);
    final projection = rule.lastProjection;
    const SteeringEngine()
        .step(agent, PrioritySteering([Seek(Vec2(80, 80)), rule]), .1);
    expect(identical(rule.lastProjection, projection), isTrue);
    expect(rule.progress, 20);
  });

  test('a complete looping trajectory accumulates laps without rewinding', () {
    final rule = FollowPolyline(elbow(loop: true),
        lookAheadDistance: 15, searchDistance: 40, cornerSlowingDistance: 35);
    var agent =
        SteeringAgent(position: Vec2.zero, maxSpeed: 40, maxAcceleration: 100);
    var previousProgress = 0.0;
    for (var i = 0; i < 3600; i++) {
      agent = const SteeringEngine().step(agent, rule, 1 / 60);
      expect(rule.progress, greaterThanOrEqualTo(previousProgress));
      previousProgress = rule.progress;
    }
    expect(rule.lapCount, greaterThanOrEqualTo(2));
  });
  test('corner speed cap has independently calculated right-angle response',
      () {
    final rule = FollowPolyline(elbow(),
        predictionTime: 0,
        lookAheadDistance: 30,
        cornerSlowingDistance: 40,
        minCornerSpeedRatio: .2,
        responseTime: 1);
    final result = rule.calculate(at(90, 0), .1);
    // cos(90)=0: corner ratio .2 + .8*.5 = .6;
    // 10/40 of preview remains: speed ratio .6 + .4*.25 = .7.
    expect(rule.lastDesiredSpeed, closeTo(7, 1e-12));
    expect(result.length, closeTo(7, 1e-12));
    final disabled =
        FollowPolyline(elbow(), predictionTime: 0, cornerSlowingDistance: 0);
    disabled.calculate(at(90, 0), .1);
    expect(disabled.lastDesiredSpeed, 10);
  });
  test('open endpoint brakes with independent expected response', () {
    final rule = FollowPolyline(elbow(),
        predictionTime: 0, slowingRadius: 11, stopRadius: 1, responseTime: .5);
    final result = rule.calculate(at(100, 94, velocity: Vec2(0, 2)), .1);
    expect(rule.currentTarget, Vec2(100, 100));
    expect(result.x, 0);
    expect(result.y, closeTo(6, 1e-12));
  });
  test(
      'full right-angle trajectory settles while respecting speed and acceleration',
      () {
    final rule = FollowPolyline(elbow(),
        lookAheadDistance: 15,
        searchDistance: 40,
        cornerSlowingDistance: 35,
        slowingRadius: 35);
    var agent =
        SteeringAgent(position: Vec2.zero, maxSpeed: 40, maxAcceleration: 100);
    var reachedSecond = false;
    for (var i = 0; i < 2400; i++) {
      final previous = agent;
      agent = const SteeringEngine().step(agent, rule, 1 / 60);
      expect((agent.velocity - previous.velocity).length * 60,
          lessThanOrEqualTo(100 + 1e-9));
      reachedSecond |= rule.progress > 100;
      expect(agent.velocity.length, lessThanOrEqualTo(40));
    }
    expect(reachedSecond, isTrue);
    expect((agent.position - Vec2(100, 100)).length, lessThan(1.1));
    expect(agent.velocity.length, lessThan(.01));
  });
  test(
      'invalid configuration and queries reject nonfinite and inconsistent values',
      () {
    final path = elbow();
    for (final bad in [-1.0, double.nan, double.infinity]) {
      expect(
          () => FollowPolyline(path, predictionTime: bad), throwsArgumentError);
      expect(() => FollowPolyline(path, lookAheadDistance: bad),
          throwsArgumentError);
      expect(
          () => FollowPolyline(path, searchDistance: bad), throwsArgumentError);
      expect(() => FollowPolyline(path, cornerSlowingDistance: bad),
          throwsArgumentError);
      expect(() => FollowPolyline(path, minCornerSpeedRatio: bad),
          throwsArgumentError);
      expect(() => FollowPolyline(path).calculate(at(0, 0), bad),
          throwsArgumentError);
      expect(() => path.pointAt(bad == -1 ? double.nan : bad),
          throwsArgumentError);
    }
    expect(() => FollowPolyline(path, minCornerSpeedRatio: 1.1),
        throwsArgumentError);
    expect(
        () => FollowPolyline(path, lookAheadDistance: 0), throwsArgumentError);
    expect(() => FollowPolyline(path, searchDistance: 0), throwsArgumentError);
    expect(() => FollowPolyline(path, stopRadius: 10, slowingRadius: 10),
        throwsArgumentError);
    expect(() => path.project(Vec2.zero, maxDistance: double.infinity),
        throwsArgumentError);
  });
}
