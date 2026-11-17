# Source release 0.2.0 / Versão de código 0.2.0

## Scope / Escopo

The 0.2.0 source adds PolylinePath, PathProjection and FollowPolyline while
preserving FollowPath waypoint capture. It includes corner-preview speed policy,
explicit reacquisition, loop progress and an independent per-agent state model.
Read the [chapter](wiki/Continuous-Path.md) for equations, tuning and measured limits.

A fonte 0.2.0 implementa os quatro itens da evolução: geometria por segmentos,
seguimento contínuo, controle de velocidade nas curvas e integração didática no
laboratório/Wiki. FollowPath mantém seu contrato anterior.

## Validation / Validação

- Sixteen new public-API tests cover numeric geometry, constrained projections,
  repeated vertices, degeneracy, prediction, forward windows, crossing branches,
  laps, independent followers, corner speed, final arrival and full trajectories.
- The previous 81 core tests remain. A complete local run passed 97 tests.
- The CLI example independently checks L-route geometry and compares corner speed
  and arrival with preview enabled/disabled; both VM and JavaScript executed locally.
- Flutter analysis/build and the new continuous-mode widget scenario are checked
  independently; exact remote CI evidence is recorded after the source push.
- Documentation checks cover all 19 behavior/composition classes, lab deep links
  and deterministic conceptual diagrams.

Local results are not remote CI evidence. The release/CI links and deployment
verification are added only after those operations complete.
Resultados locais não substituem evidência do CI; a publicação é conferida à parte.

## Hosted status / Estado hospedado

This source version does not establish that pub.dev hosts 0.1.0 or 0.2.0. Access
to pub.dev was denied by the browser approval gate during the previous follow-up.
No package upload, publisher transfer or hosted score is claimed. The intended
publisher remains kleberandrade.dev, subject to verification of actual ownership.

A versão hospedada e o publisher continuam sem confirmação. A primeira publicação
precisa do fluxo Dart CLI com autenticação do usuário. A publicação GitHub/Pages
não executa esse upload. Consulte o [histórico da 0.1.0](release_0.1.0.md).

## Verified remote evidence / Evidência remota verificada

- [CI 44031135395](https://github.com/kleberandrade/steering-engine/actions/runs/44031135395)
  passed at commit 6bbd346: Dart 3.3/stable, all 97 core tests, handbook checks,
  VM/JavaScript examples, pub dry run, Flutter/Flame tests and web builds, followed
  by successful GitHub Pages deployment.
- [GitHub release and tag v0.2.0](https://github.com/kleberandrade/steering-engine/releases/tag/v0.2.0)
  was visibly verified at the same validated commit. This is a source release.
- Wiki mirror commit 02b9f34 publishes the continuous-path chapter and image.
  The local mirror-equivalence check reports zero differences.
- Ten repository discovery topics, description and Pages website were visibly
  verified in About. They are separate from the version tag.

The first source CI attempt stopped on scene-test title formatting under Dart
3.14. Shortening that title fixed the check; no checks were weakened or skipped.
Live browser inspection of the prior web deployment was interrupted; the deployment
and widget-test evidence above do not imply an additional visual browser check.
