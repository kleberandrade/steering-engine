# Release 0.1.0 validation

## Included behavior families

| Family | API | Validation |
| --- | --- | --- |
| Waypoint path | FollowPath, SteeringPath | Capture, loop, reset and final arrival tests; CLI and lab |
| Leader | LeaderFollowing | Rotated/stationary heading, clearance and arrival tests; lab |
| Spatial queue | QueueFollowing | Lane selection, spacing, retained lateral movement and stopped hold; lab |
| Wall | WallFollowing, WallSegment | Projection, offset sides and forward convergence; lab |
| Flocking | Separation, Alignment, Cohesion, Flocking | Independent math and shared-frame tests; CLI and lab |
| Spatial lookup | AgentNeighborhood.spatial | Seeded identity/order/force equivalence and fallback tests |
| Flame | SteeringDemoGame, AgentView example | Independent stable-Flutter analysis, tests and web build |

## Source and publication state

- Version 0.1.0 is prepared in pubspec and changelog.
- Core remains Dart >=3.3, zero runtime dependencies and no Flutter/IO imports.
- The local suite has 81 core tests. CI additionally runs Flutter and Flame tests,
  CLI/JavaScript examples and the publication dry run.
- Native benchmark methodology and raw reports are under `doc/benchmarks/`.
- Release-source CI [44020825763](https://github.com/kleberandrade/steering-engine/actions/runs/44020825763)
  completed successfully: Dart 3.3/stable, 81 core tests, five Flutter lab tests,
  two Flame tests, JavaScript examples, both web builds and publication dry run.
- GitHub source release [v0.1.0](https://github.com/kleberandrade/steering-engine/releases/tag/v0.1.0)
  was created at validated commit d07f32d.
- **The first pub.dev upload remains pending.** Computer Use denied access to
  Terminal, and the command executor cannot resolve publication dependencies in
  its restricted cache environment. No hosted publication or pub score is claimed.
- Complete the first upload from a normal developer terminal:

```sh
cd /Users/kleber/Projects/steering-engine
dart pub publish
```

Verify https://pub.dev/packages/steering_engine/versions/0.1.0 after the upload.
The first version must use the Dart CLI; automated publishing can be configured
only after the package exists, per the official
[automated publishing documentation](https://dart.dev/tools/pub/automated-publishing).

## Português

O inventário acima continua sendo da versão de código. A confirmação hospedada
é tratada separadamente no acompanhamento ao final.

O inventário acima confere path following, leader following, queue e wall
following. A release de código v0.1.0 está no GitHub, com CI verde. O upload inicial no
pub.dev continua pendente: execute o comando acima em um terminal normal e
confirme a página da versão hospedada.
A metodologia dos benchmarks evita promessas gerais de FPS ou memória por índice.

## Follow-up / Acompanhamento

Publication/publisher confirmation was attempted again on 2026-11-17. The browser
origin approval gate denied access to pub.dev; no alternate route was used after
that denial. Hosted version and publisher remain unverified. The README includes
the future hosted dependency syntax, explicitly conditional on verified upload.
The source version remains 0.1.0. No publisher transfer or hosted upload is claimed.

A confirmação da versão e do publisher continua pendente por bloqueio de acesso
ao pub.dev. Os laboratórios web e o plano da 0.2.0 são entregas independentes.
