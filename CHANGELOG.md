# Changelog

## Unreleased

- Prepare a disabled-by-default stable-tag/OIDC publishing workflow with version
  matching and minimum/stable Dart gates; manual runs are validation only.
- Add compact/portrait/landscape lab interaction checks and the proposed 0.3.0
  tracking-quality plan. / Publicação preparada, testes mobile e plano da 0.3.0.

## 0.2.0 — 2026-11-17

Source release; pub.dev availability is verified separately.

- Add immutable PolylinePath geometry, finite PathProjection queries and arc-length
  sampling, with explicit duplicate-edge and degenerate-route policies.
- Add per-agent FollowPolyline with predicted-position projection, forward progress
  windows, loop laps, explicit reset/reacquisition and final arrival.
- Add configurable corner-preview speed reduction, independent mathematical tests
  and a measured trajectory comparison; existing FollowPath remains unchanged.
- Add a continuous-path lab mode with projection/arc target visualization and a
  bilingual Wiki chapter, diagram, executable Dart/JS example and regression checks.
- Geometria por segmentos, seguimento contínuo, antecipação de curvas, laboratório
  e documentação bilíngue; o seguidor por waypoints mantém o comportamento anterior.

- Publish the checked Flutter/Flame web artifacts through GitHub Pages; add
  chapter links that select the corresponding laboratory scene on startup.
  / Laboratórios web e links diretos dos capítulos para cada comportamento.
- Record the implemented continuous-path design, compatibility and acceptance
  criteria with the original waypoint behavior preserved.

- Bilingual learning handbook and GitHub Wiki covering all 19 steering behaviors
  and composition strategies, with conceptual diagrams, pseudocode, tuning,
  worked examples and troubleshooting. / Guia didático bilíngue e Wiki.
- Reproducible diagram generation, documentation checks and Wiki export tooling.

## 0.1.0 — 2026-11-17

Initial release source:

- Pure Dart immutable vectors/agents and bounded semi-implicit Euler integration.
- Seek, Flee, Arrive, Pursuit, Evade, seeded Wander and Brake.
- Weighted and priority composition with runtime numeric validation.
- Waypoint path following, leader following, movement-filtering spatial queues
  and finite-segment wall following.
- Static circular obstacle avoidance, agent radius and read-only threat queries.
- Shared-frame Separation, Alignment, Cohesion and Flocking.
- Optional spatial-grid lookup preserving linear neighbor order and exact filtering,
  with conservative numeric/large-query fallbacks.
- Reproducible native timing/RSS reports and an adjustable 24/100/500/1000-agent lab.
- Separate Flame example and independent Flutter/Flame CI checks.
- English/Portuguese guides, visual diagrams and scientific references.
- Organized core, math, geometry, perception, navigation and behavior modules.

Source/release notes do not themselves perform pub.dev publication. Hosted
availability is verified separately in the release validation record.
