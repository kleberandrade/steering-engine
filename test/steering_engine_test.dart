import 'dart:math' as math;

import 'package:steering_engine/steering_engine.dart';
import 'package:test/test.dart';

class Constant implements SteeringBehavior {
  Constant(this.value);
  final Vec2 value;
  int calls = 0;
  @override
  Vec2 calculate(SteeringAgent agent, double dt) {
    calls++;
    return value;
  }
}

void expectVector(Vec2 actual, double x, double y, [double tolerance = 1e-9]) {
  expect(actual.x, closeTo(x, tolerance));
  expect(actual.y, closeTo(y, tolerance));
}

void main() {
  group('Vec2', () {
    test('operations and 3-4-5 normalization', () {
      final a = Vec2(3, 4);
      expect(a.length, 5);
      expectVector(a.normalized, 0.6, 0.8);
      expectVector(a + Vec2(1, -1), 4, 3);
      expectVector(a - Vec2(1, -1), 2, 5);
      expectVector(-a, -3, -4);
      expectVector(a * 2, 6, 8);
      expectVector(a / 2, 1.5, 2);
      expectVector(a, 3, 4);
    });
    test('limited vectors remain within strict state speed boundaries', () {
      final random = math.Random(42);
      for (var i = 0; i < 10000; i++) {
        final cap = random.nextDouble() * 300;
        final vector =
            Vec2(random.nextDouble() * 1000, random.nextDouble() * 1000)
                .limited(cap);
        expect(vector.length, lessThanOrEqualTo(cap));
        SteeringAgent(position: Vec2.zero, velocity: vector, maxSpeed: cap);
      }
    });
    test('limits magnitude and handles zero', () {
      expectVector(Vec2(3, 4).limited(2), 1.2, 1.6);
      expectVector(Vec2(3, 4).limited(0), 0, 0);
      expectVector(Vec2.zero.normalized, 0, 0);
    });
    test('normalization avoids intermediate square overflow', () {
      expectVector(Vec2(3e200, 4e200).normalized, 0.6, 0.8);
      expectVector(Vec2(3e-200, 4e-200).normalized, 0.6, 0.8);
    });
    test('rejects nonfinite and unrepresentable vectors', () {
      for (final bad in [double.nan, double.infinity, -double.infinity]) {
        expect(() => Vec2(bad, 0), throwsArgumentError);
        expect(() => Vec2(0, bad), throwsArgumentError);
      }
      expect(() => Vec2(1.7e308, 1.7e308), throwsArgumentError);
      expect(() => Vec2(1, 1) / 0, throwsArgumentError);
      expect(() => Vec2(1, 1) * double.nan, throwsArgumentError);
      expect(() => Vec2(1, 1).limited(-1), throwsArgumentError);
    });
  });

  final agent = SteeringAgent(
      position: Vec2.zero,
      velocity: Vec2(2, 0),
      maxSpeed: 10,
      maxAcceleration: 100);
  group('behavior mathematics', () {
    test('seek converts desired velocity into acceleration', () {
      expectVector(
          Seek(Vec2(3, 4), responseTime: 0.5).calculate(agent, 0.1), 8, 16);
    });
    test('flee reverses desired velocity, including existing momentum', () {
      expectVector(
          Flee(Vec2(3, 4), responseTime: 0.5).calculate(agent, 0.1), -16, -16);
    });
    test('coincident target brakes without NaN', () {
      expectVector(
          Seek(Vec2.zero, responseTime: 0.5).calculate(agent, 0), -4, 0);
      expectVector(
          Flee(Vec2.zero, responseTime: 0.5).calculate(agent, 0), -4, 0);
    });
    test('seek respects acceleration limit', () {
      final bounded = SteeringAgent(position: Vec2.zero, maxAcceleration: 2);
      expect(Seek(Vec2(3, 4)).calculate(bounded, 1).length, closeTo(2, 1e-9));
    });
    test('arrival interpolates desired speed between radii', () {
      final arrive = Arrive(Vec2(6, 0),
          slowingRadius: 11, stopRadius: 1, responseTime: 0.5);
      // desired speed = 10 * (6 - 1)/(11 - 1) = 5; acceleration = (5 - 2)/0.5.
      expectVector(arrive.calculate(agent, 0.1), 6, 0);
    });
    test('arrival brakes inside stop radius and seeks outside slowing radius',
        () {
      expectVector(
          Arrive(Vec2(0.5, 0), responseTime: 0.5).calculate(agent, 1), -4, 0);
      expectVector(
          Arrive(Vec2(200, 0), responseTime: 0.5).calculate(agent, 1), 16, 0);
    });
    test('pursuit predicts with a capped horizon', () {
      final target = SteeringAgent(position: Vec2(30, 0), velocity: Vec2(0, 4));
      // distance/speed = 3 s, capped at 1 s; predicted position = (30, 4).
      final result = Pursuit(target, maxPrediction: 1, responseTime: 1)
          .calculate(agent, 1);
      expectVector(result, 10 * 30 / 30.265491900843113 - 2,
          10 * 4 / 30.265491900843113);
    });
    test('evade flees prediction and zero horizon uses current target', () {
      final target = SteeringAgent(position: Vec2(3, 4), velocity: Vec2(0, 4));
      expectVector(
          Evade(target, maxPrediction: 0, responseTime: 0.5)
              .calculate(agent, 1),
          -16,
          -16);
      final stationary = SteeringAgent(position: Vec2.zero, maxSpeed: 0);
      expectVector(Pursuit(target).calculate(stationary, 1), 0, 0);
    });
    test('seeded wander repeats the same calls and respects bounds', () {
      final a = Wander(seed: 42);
      final b = Wander(seed: 42);
      final c = Wander(seed: 43);
      var differs = false;
      for (var i = 0; i < 100; i++) {
        final av = a.calculate(agent, 1 / 60);
        final bv = b.calculate(agent, 1 / 60);
        final cv = c.calculate(agent, 1 / 60);
        expectVector(av, bv.x, bv.y);
        expect(av.length, lessThanOrEqualTo(agent.maxAcceleration + 1e-9));
        differs |= (av - cv).length > 1e-6;
      }
      expect(differs, isTrue);
    });
    test('zero dt does not consume wander randomness', () {
      final a = Wander(seed: 7);
      final b = Wander(seed: 7);
      a.calculate(agent, 0);
      final result = a.calculate(agent, 0.1);
      final expected = b.calculate(agent, 0.1);
      expectVector(result, expected.x, expected.y);
    });
  });

  group('composition', () {
    test('blend uses unnormalized weights and copies configuration', () {
      final entries = [
        WeightedBehavior(Constant(Vec2(2, 0)), weight: 0.5),
        WeightedBehavior(Constant(Vec2(0, 3)), weight: 2)
      ];
      final blend = WeightedBlend(entries);
      entries.clear();
      expectVector(blend.calculate(agent, 0.1), 1, 6);
      expect(() => blend.entries.clear(), throwsUnsupportedError);
    });
    test('blend skips disabled stateful behaviors and caps total', () {
      final disabled = Constant(Vec2(100, 100));
      final blend = WeightedBlend([
        WeightedBehavior(disabled, weight: 0),
        WeightedBehavior(Constant(Vec2(300, 400))),
      ]);
      expectVector(blend.calculate(agent, 1), 60, 80);
      expect(disabled.calls, 0);
    });
    test('opposite forces cancel; empty blend returns zero', () {
      expectVector(WeightedBlend([]).calculate(agent, 0), 0, 0);
      expectVector(
          WeightedBlend([
            WeightedBehavior(Constant(Vec2(5, 0))),
            WeightedBehavior(Constant(Vec2(-5, 0))),
          ]).calculate(agent, 1),
          0,
          0);
    });
    test(
        'priority selects first above threshold without evaluating later entries',
        () {
      final later = Constant(Vec2(10, 0));
      final items = <SteeringBehavior>[
        Constant(Vec2(0.01, 0)),
        Constant(Vec2(0, 3)),
        later
      ];
      final priority = PrioritySteering(items, epsilon: 0.1);
      items.clear();
      expectVector(priority.calculate(agent, 1), 0, 3);
      expect(later.calls, 0);
      expect(() => priority.behaviors.clear(), throwsUnsupportedError);
      expectVector(PrioritySteering([]).calculate(agent, 1), 0, 0);
    });
    test('priority caps a custom behavior output', () {
      expectVector(
          PrioritySteering([Constant(Vec2(300, 400))]).calculate(agent, 1),
          60,
          80);
    });
  });

  test('Brake decelerates and validates response time', () {
    expectVector(Brake(responseTime: 0.5).calculate(agent, 1), -4, 0);
    expect(() => Brake(responseTime: 0), throwsArgumentError);
    expect(() => Brake().calculate(agent, -1), throwsArgumentError);
  });

  group('integration', () {
    const engine = SteeringEngine();
    test('semi-implicit Euler uses new velocity for position', () {
      final next = engine.step(agent, Constant(Vec2(0, 4)), 0.5);
      expectVector(next.velocity, 2, 2);
      expectVector(next.position, 1, 1);
      expectVector(agent.position, 0, 0);
      expectVector(agent.velocity, 2, 0);
    });
    test('caps custom acceleration before integration and then speed', () {
      final initial =
          SteeringAgent(position: Vec2.zero, maxSpeed: 2, maxAcceleration: 1);
      final next = engine.step(initial, Constant(Vec2(300, 400)), 1);
      expectVector(next.velocity, 0.6, 0.8);
      final fast = engine.step(initial, Constant(Vec2(300, 400)), 10);
      expectVector(fast.velocity, 1.2, 1.6);
    });
    test('zero dt preserves identity without evaluating behavior', () {
      final behavior = Constant(Vec2(1, 1));
      expect(identical(engine.step(agent, behavior, 0), agent), isTrue);
      expect(behavior.calls, 0);
    });
    test('zero acceleration preserves momentum and zero speed stays still', () {
      final coasting = SteeringAgent(
          position: Vec2.zero, velocity: Vec2(1, 0), maxAcceleration: 0);
      expectVector(engine.step(coasting, Seek(Vec2(10, 10)), 1).position, 1, 0);
      final stopped = SteeringAgent(position: Vec2.zero, maxSpeed: 0);
      expectVector(engine.step(stopped, Seek(Vec2(10, 10)), 1).position, 0, 0);
    });
    test('arrival converges in a complete simulation', () {
      var current = SteeringAgent(
          position: Vec2.zero, maxSpeed: 80, maxAcceleration: 160);
      final behavior = Arrive(Vec2(200, 100), slowingRadius: 80);
      for (var i = 0; i < 1200; i++) {
        current = engine.step(current, behavior, 1 / 60);
      }
      expect((current.position - behavior.target).length, lessThan(1.01));
      expect(current.velocity.length, lessThan(0.01));
    });
  });

  group('validation', () {
    test('invalid numeric configuration throws in normal runtime code', () {
      for (final bad in [-1.0, double.nan, double.infinity]) {
        expect(() => SteeringAgent(position: Vec2.zero, maxSpeed: bad),
            throwsArgumentError);
        expect(() => SteeringAgent(position: Vec2.zero, maxAcceleration: bad),
            throwsArgumentError);
        expect(() => WeightedBehavior(Seek(Vec2.zero), weight: bad),
            throwsArgumentError);
        expect(() => PrioritySteering([], epsilon: bad), throwsArgumentError);
        expect(() => Wander(jitter: bad), throwsArgumentError);
        expect(() => Wander(radius: bad), throwsArgumentError);
        expect(() => Pursuit(agent, maxPrediction: bad), throwsArgumentError);
        expect(() => Evade(agent, maxPrediction: bad), throwsArgumentError);
      }
      for (final bad in [0.0, -1.0, double.nan, double.infinity]) {
        expect(() => Seek(Vec2.zero, responseTime: bad), throwsArgumentError);
        expect(() => Flee(Vec2.zero, responseTime: bad), throwsArgumentError);
        expect(() => Arrive(Vec2.zero, responseTime: bad), throwsArgumentError);
        expect(() => Pursuit(agent, responseTime: bad), throwsArgumentError);
        expect(() => Evade(agent, responseTime: bad), throwsArgumentError);
        expect(() => Wander(responseTime: bad), throwsArgumentError);
        expect(() => Wander(distance: bad), throwsArgumentError);
      }
      expect(() => Arrive(Vec2.zero, slowingRadius: 1, stopRadius: 1),
          throwsArgumentError);
      expect(() => Arrive(Vec2.zero, stopRadius: -1), throwsArgumentError);
      expect(() => Arrive(Vec2.zero, slowingRadius: double.nan),
          throwsArgumentError);
      expect(
          () => SteeringAgent(
              position: Vec2.zero, velocity: Vec2(11, 0), maxSpeed: 10),
          throwsArgumentError);
    });
    test('negative and nonfinite elapsed time is rejected throughout API', () {
      final behaviors = <SteeringBehavior>[
        Seek(Vec2.zero),
        Flee(Vec2.zero),
        Arrive(Vec2.zero),
        Pursuit(agent),
        Evade(agent),
        Wander(seed: 1),
        WeightedBlend([]),
        PrioritySteering([]),
      ];
      for (final dt in [-0.1, double.nan, double.infinity]) {
        for (final behavior in behaviors) {
          expect(() => behavior.calculate(agent, dt), throwsArgumentError);
          expect(() => const SteeringEngine().step(agent, behavior, dt),
              throwsArgumentError);
        }
      }
    });
  });
}
