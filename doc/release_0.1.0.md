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
- Publication is pending the final validated source synchronization. A successful
  dry run is not an upload; hosted version and package metadata are verified after
  the actual publish command. No pub score is claimed in advance.

## Português

O inventário acima confere path following, leader following, queue e wall
following. O código está preparado como 0.1.0; a publicação real é um passo
separado e sua confirmação será registrada após verificar a versão hospedada.
A metodologia dos benchmarks evita promessas gerais de FPS ou memória por índice.
