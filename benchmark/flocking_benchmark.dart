import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:steering_engine/steering_engine.dart';

void main(List<String> args) {
  final count = args.isEmpty ? 100 : int.parse(args[0]);
  final frames = args.length < 2 ? 15 : int.parse(args[1]);
  final indexed = args.length > 2 && args[2] == 'spatial';
  final random = math.Random(42);
  final side = math.sqrt(count) * 35;
  final agents = List.generate(
      count,
      (_) => SteeringAgent(
          position:
              Vec2(random.nextDouble() * side, random.nextDouble() * side),
          velocity: Vec2(
              random.nextDouble() * 40 - 20, random.nextDouble() * 40 - 20),
          maxSpeed: 100,
          maxAcceleration: 150));
  final timings = <int>[];
  var checksum = 0.0;
  final before = ProcessInfo.currentRss;
  for (var frame = 0; frame < frames + 5; frame++) {
    final timer = Stopwatch()..start();
    final observed =
        indexed ? AgentNeighborhood.spatial(agents) : AgentNeighborhood(agents);
    final rule = Flocking(observed);
    for (final agent in agents) {
      final next = const SteeringEngine().step(agent, rule, 1 / 60);
      checksum += next.velocity.x + next.velocity.y;
    }
    timer.stop();
    if (frame >= 5) timings.add(timer.elapsedMicroseconds);
  }
  timings.sort();
  print(jsonEncode({
    'strategy': indexed ? 'spatial' : 'linear',
    'agents': count,
    'frames': frames,
    'warmup': 5,
    'median_us': timings[timings.length ~/ 2],
    'p95_us': timings[((timings.length - 1) * .95).ceil()],
    'rss_before_bytes': before,
    'rss_after_bytes': ProcessInfo.currentRss,
    'peak_rss_bytes': ProcessInfo.maxRss,
    'checksum': checksum,
    'sdk': Platform.version.split('\n').first,
    'os': Platform.operatingSystem,
    'fixture':
        'seed42, fixed-density uniform positions, repeated identical frame',
  }));
}
