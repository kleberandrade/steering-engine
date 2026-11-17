# steering_engine

[![Dart CI](https://github.com/kleberandrade/steering-engine/actions/workflows/ci.yml/badge.svg)](https://github.com/kleberandrade/steering-engine/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-6ae4d4.svg)](LICENSE)

**Composable 2D steering behaviors in pure Dart**, for Flutter games, autonomous
characters and simulations. No runtime dependencies, Flutter imports, IO or network
access in the core.

[Português](README.pt-BR.md) · [Getting started](doc/getting_started.md) ·
[Learning guide](doc/wiki/Home.md) · [Wiki](https://github.com/kleberandrade/steering-engine/wiki) ·
[Online lab](https://kleberandrade.github.io/steering-engine/) ·
[Equations](doc/behaviors.md) · [Architecture](doc/architecture.md) ·
[Flutter lab](example/flutter_lab/README.md) · [Roadmap](doc/roadmap.md) ·
[Flocking](doc/flocking.md) · [Obstacle avoidance](doc/obstacle_avoidance.md) · [Path following](doc/path_following.md) · [Contributing](CONTRIBUTING.md)

![Steering behavior concepts](doc/images/steering.svg)

## Learn step by step

A behavior turns a goal into **acceleration**. The engine integrates it into
velocity and position; your Flutter or Flame application draws the result.
Start with [units, vectors and a complete loop](doc/wiki/Foundations.md), then
compare [Seek](doc/wiki/Seek.md) (approach) with [Arrive](doc/wiki/Arrive.md)
(approach and slow down).

The bilingual [learning guide](doc/wiki/Home.md) and
[GitHub Wiki](https://github.com/kleberandrade/steering-engine/wiki) explain all
18 behaviors and composition strategies with diagrams, pseudocode, parameters,
Dart snippets, experiments and limits.

| Learn | Chapters |
| --- | --- |
| Move one agent | [Seek](doc/wiki/Seek.md), [Flee](doc/wiki/Flee.md), [Arrive](doc/wiki/Arrive.md), [Brake](doc/wiki/Brake.md) |
| Anticipate and explore | [Pursuit](doc/wiki/Pursuit.md), [Evade](doc/wiki/Evade.md), [Wander](doc/wiki/Wander.md) |
| Combine decisions | [Weighted blend](doc/wiki/Weighted-Blend.md), [Priority](doc/wiki/Priority-Steering.md) |
| Navigate geometry | [Path](doc/wiki/Path-Following.md), [Obstacles](doc/wiki/Obstacle-Avoidance.md), [Walls](doc/wiki/Wall-Following.md) |
| Move together | [Separation](doc/wiki/Separation.md), [Alignment](doc/wiki/Alignment.md), [Cohesion](doc/wiki/Cohesion.md), [Flocking](doc/wiki/Flocking.md) |
| Organize and scale | [Leader](doc/wiki/Leader-Following.md), [Queue](doc/wiki/Queue-Following.md), [Spatial index](doc/wiki/Spatial-Index.md) |

For practical combinations and common problems, see
[recipes and troubleshooting](doc/wiki/Recipes.md).

## Status and installation

Source version **0.1.0**, prepared for the first hosted release. Publication is
verified separately from source versioning; see [release validation](doc/release_0.1.0.md).
The core requires Dart **>=3.3.0 <4.0.0**, with no Flutter or Flame dependency.
Before hosted availability is confirmed, use a local path or a reviewed Git ref.

```yaml
dependencies:
  steering_engine:
    path: ../steering-engine
```

The [Flutter lab](example/flutter_lab/README.md) and [Flame example](doc/flame.md)
have their own SDK constraints and are validated independently.

### Hosted installation after publication is confirmed

Once version 0.1.0 is confirmed on [pub.dev](https://pub.dev/packages/steering_engine),
the hosted dependency is:

```yaml
dependencies:
  steering_engine: ^0.1.0
```

Until then, use the local-path setup above. Publisher ownership and hosted
availability are tracked independently in the release audit; this example does
not confirm an upload. The [0.2.0 plan](doc/roadmap_0.2.0.md) is separate from 0.1.0.

## Make a character arrive

```dart
import 'package:steering_engine/steering_engine.dart';

void main() {
  const engine = SteeringEngine();
  var agent = SteeringAgent(
    position: Vec2.zero,
    maxSpeed: 80,
    maxAcceleration: 160,
  );
  final behavior = Arrive(Vec2(200, 100), slowingRadius: 80);

  for (var frame = 0; frame < 600; frame++) {
    agent = engine.step(agent, behavior, 1 / 60);
  }
  print(agent.position); // Near (200, 100), with bounded deceleration.
}
```

Position uses your distance units; velocity is units/second, acceleration is
units/second², and `dt` is seconds. Render `agent.position` with Flutter
`CustomPainter`, or copy it into a Flame component in your game loop.

## Choose a behavior

| Behavior | Goal | Important detail |
| --- | --- | --- |
| `Seek` | Approach a position | Can overshoot; does not plan a stop |
| `Flee` | Move away from a position | Exact overlap has no escape direction |
| `Arrive` | Approach and slow down | Brakes inside the stop radius; no teleportation |
| `Pursuit` | Intercept a moving target | Linear prediction, bounded by `maxPrediction` |
| `Evade` | Escape a moving threat | Flees the predicted position |
| `Wander` | Explore without a fixed destination | Own one seeded, stateful instance per agent |
| `Brake` | Reduce velocity toward zero | Obeys the acceleration limit |

`Pursuit` and `Evade` capture immutable target snapshots: rebuild them when the
target updates. All built-in behaviors return bounded **acceleration**, not force.

## Follow a route

```dart
final route = SteeringPath([
  Vec2(80, 0), Vec2(80, 80), Vec2(160, 80),
]);
final follower = FollowPath(route, waypointRadius: 5, slowingRadius: 35);
// Keep the follower instance across frames: it owns the current waypoint.
agent = engine.step(agent, follower, 1 / 60);
```

Use `loop: true` on SteeringPath for a repeating route. Inspect
`follower.waypointIndex` and `currentTarget`, or call `reset()` to rewind.
Run `dart run example/path_following.dart`. See the [route guide](doc/path_following.md).

## Steer around static obstacles

```dart
final avoidance = ObstacleAvoidance([
  CircleObstacle(Vec2(80, 0), radius: 15),
], agentRadius: 5, safetyMargin: 4, lookAheadTime: 1.5);
final steering = PrioritySteering([
  avoidance,
  Arrive(Vec2(180, 0), slowingRadius: 40),
]);
```

The scan accounts for agent size and selects the first predicted circle surface.
It requests lateral acceleration and braking, or zero when the local path is clear.
Compose it before a destination or route follower. `findThreat` exposes read-only
debug geometry. This reactive method does not resolve or guarantee prevention of
collisions. See the [visual guide and limits](doc/obstacle_avoidance.md).
Run `dart run example/obstacle_avoidance.dart` for a complete checked simulation.

## Combine behaviors

```dart
final steering = WeightedBlend([
  WeightedBehavior(Arrive(Vec2(300, 100)), weight: 0.8),
  WeightedBehavior(Wander(seed: 42), weight: 0.2),
]);
```

Weights multiply accelerations without automatic normalization. The sum is capped
to the agent's acceleration limit. Zero weight skips evaluation entirely.
For ordered alternatives, `PrioritySteering([primary, fallback], epsilon: 0.001)`
chooses the first output whose magnitude exceeds the threshold. Later behaviors
are not evaluated. It is selection, not an accumulated force budget.

Implement `SteeringBehavior.calculate(agent, dt)` to add a custom algorithm.
The engine caps custom outputs before integrating motion.

## Flock with local neighbors

Build one `AgentNeighborhood(agents)` per frame and evaluate all agents against
that shared observation. `Separation`, `Alignment` and `Cohesion` can be used
independently; `Flocking` composes them through `WeightedBlend`.

```dart
final observed = AgentNeighborhood(agents);
final flocking = Flocking(observed,
  separationRadius: 25, neighborRadius: 80,
  separationWeight: 1.5, alignmentWeight: 1, cohesionWeight: 0.7,
);
agents = [
  for (final agent in agents)
    const SteeringEngine().step(agent, flocking, 1 / 60),
];
```

Replace the complete frame after evaluation. Neighbor queries exclude the
observer by identity; use the original snapshot, not a copy. The current query
is linear in this constructor, so full-flock work is O(n²); use
`AgentNeighborhood.spatial(agents)` for optional grid lookup. See the [equations and visual guide](doc/flocking.md)
and run `dart run example/flocking.dart`. The lab compares each rule and lets
you tune weights for 24, 100, 500 or 1000 agents. Flocking does not provide collision resolution.

## Explore visually

[Open the online laboratory](https://kleberandrade.github.io/steering-engine/) or
the [Flame demo](https://kleberandrade.github.io/steering-engine/flame/).
Wiki chapters link directly to the relevant scene, for example
[wall following](https://kleberandrade.github.io/steering-engine/?mode=Wall%20following).
To run locally:

```sh
cd example/flutter_lab
flutter pub get
flutter run -d chrome
```

The lab offers individual and collective behaviors, path following, obstacle avoidance and compositions,
click/drag targets, a moving target, a seeded wander stream, velocity and
acceleration arrows, trails, adjustable limits, pause, reset and fixed-step
advancement. World edges wrap in the demo; the core leaves boundaries to callers.

## Numerical model and limits

- Immutable vectors and agent snapshots; copied, unmodifiable composition lists.
- Validated finite parameters, nonnegative limits and `dt`; positive response time.
- Semi-implicit Euler: update velocity, cap speed, then update position.
- `dt == 0` is an engine no-op and does not evaluate stateful behaviors.
- Small fixed steps are recommended. Large steps can overshoot, and blending
  conflicting goals may cancel motion or prevent arrival.
- Wander seeds reproduce matching call sequences on the same runtime; trajectories
  are not promised identical across different time steps or runtimes.
- Collision resolution, vehicle dynamics and moving-obstacle prediction remain future work.
  Obstacle avoidance supports static circles. Wall following provides local
  segment guidance, without contact resolution or wall-avoidance guarantees.
  Steering can consume a planned route; it does not replace pathfinding.

See [equations and conventions](doc/behaviors.md) for exact formulas.

## Spatial index and following modes

Use `AgentNeighborhood.spatial(agents)` for optional grid lookup with the same
neighbor order and exact filtering. Compare populations and measured tick cost
in the lab. Read [spatial lookup](doc/spatial_index.md), [benchmarks](doc/benchmarks/README.md),
[leader / queue / wall following](doc/following.md) and [Flame integration](doc/flame.md).
All four following families, including the existing waypoint follower, are covered.

## Development

```sh
dart pub get
dart analyze --fatal-infos
dart test
dart run example/steering_engine_example.dart
dart run example/composition.dart
```

CI also checks JavaScript compilation, the Flutter lab and a publication dry run.
See [CONTRIBUTING.md](CONTRIBUTING.md) for the complete checks.

## Scientific references

1. Reynolds, C. W. (1999). [Steering Behaviors for Autonomous Characters](https://www.red3d.com/cwr/steer/gdc99/). Game Developers Conference. Conceptual basis for local movement and behavior composition.
2. Reynolds, C. W. (1987). [Flocks, Herds, and Schools: A Distributed Behavioral Model](https://www.red3d.com/cwr/boids/). SIGGRAPH. Conceptual foundation for the collective behaviors.

This implementation uses an explicit acceleration/response-time convention and
bounded prediction, documented above; it is not a verbatim port of Reynolds's demos.
