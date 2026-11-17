# Roadmap / Próximos passos

## 0.1 foundation / Base implementada

- Seven local behaviors / Sete comportamentos locais.
- Immutable 2D state, limits, composition and public API tests.
- Flutter lab, bilingual guides and scientific references.

## Implemented next / Nova etapa implementada

- Immutable waypoint routes, independent per-agent traversal, looping or final
  arrival, capture-radius following, reset and a visual route demo.
- Rotas por waypoints, estado de percurso por agente, repetição ou chegada final,
  reinício e demonstração visual. Segment projection remains future work.

## Static obstacle avoidance / Desvio de obstáculos implementado

- Immutable static circles, inflated ray geometry, earliest surface selection,
  overlap escape and lateral/braking acceleration.
- Read-only threat inspection, priority composition and adjustable visual lab.
- Círculos estáticos, raio do agente, margem de detecção, composição por prioridade
  e exemplos com medição de separação. No collision solver or guarantee.

## Collective movement / Movimento coletivo implementado

- Shared immutable AgentNeighborhood observations, separation with linear falloff,
  velocity alignment, positional cohesion and composable flocking.
- Synchronous frame updates and a 24-agent lab with independent rule/weight controls.
- Observações compartilhadas, atualização simultânea e demonstração com 24 agentes.
  Spatial queries remain linear and whole-flock evaluation remains O(n²).

## Spatial perception and following / Busca e seguimento

- Optional uniform grid with exact linear-equivalence tests and numeric fallback.
- Native AOT timings and process RSS at 100/500/1000 agents, with raw reports.
- Lab population controls, index comparison, physics timing and catch-up limits.
- Dedicated Flame 1.38 example with separate analysis/tests/web-build CI.
- Path, leader, queue and wall following; public tests and visual demonstrations.
- Grade opcional, medições reproduzíveis, laboratório ampliado e integração Flame.

## Release / Publicação

Source 0.1.0 is prepared and verified by CI; actual pub.dev publication is recorded
separately in [release validation](release_0.1.0.md). No source version or tag alone
is evidence that a hosted package exists.

## Future / Evolução futura

- Continuous segment-projection path following and richer corner handling.
- Dynamic obstacle prediction, wall avoidance/contact resolution and vehicle models.
- Larger-scene profiling and additional neighbor-search strategies.
- Projeção contínua, obstáculos móveis e física permanecem fora da versão inicial.
