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

## Next / Próximas etapas

1. Spatial neighbor lookup and measured multi-agent performance.
2. Optional Flame integration guide and a dedicated example.
3. Publication review, stable version and a separate pub.dev publication.

Estas etapas são planejamento, não funcionalidades já disponíveis. Não há
cronograma ou compatibilidade de API futura garantidos durante a fase inicial.
