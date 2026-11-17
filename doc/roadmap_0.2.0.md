# 0.2.0 — continuous path following / seguimento contínuo

**Planning, not implemented or released. / Planejamento, sem implementação ou release.**

The priority is smoother guidance along polylines without changing existing
waypoint traversal. The source package remains 0.1.0 until the new behavior is
implemented, reviewed and validated. Public names below are design proposals.

A prioridade é acompanhar uma polilinha com antecipação, preservando `FollowPath`
e seu contrato de captura de waypoints. Os nomes de API abaixo são propostas;
este documento não anuncia funcionalidades já disponíveis.

## Scope and compatibility / Escopo e compatibilidade

| Item | Decision / Decisão |
| --- | --- |
| Existing `FollowPath` | Preserve capture-radius behavior, index, reset and final Arrive / preservar contrato atual |
| Proposed `FollowPolyline` | Separate stateful behavior, one per follower / nova regra com estado por agente |
| Geometry | Reuse immutable route points; precompute nonzero segment lengths and cumulative distance / geometria compartilhável |
| Projection | Pure result with segment index, local fraction, projected point and arc distance / resultado imutável e inspecionável |
| Prediction | Project a forward-predicted position, then advance along route arc length / projetar observação futura e avançar no percurso |
| Open/looped route | Open route ends with bounded Arrive; closed route wraps arc distance / chegada final ou repetição |
| Sharp corners | Advance the target through corners and evaluate speed reduction from turn geometry / antecipação e redução de velocidade |
| Pure Dart | No Flutter, IO, mass, wheel model or collision solver / núcleo permanece independente |

## Proposed algorithm / Algoritmo proposto

```text
build immutable route geometry:
    discard zero-length edges from segment traversal, keeping waypoint API intact
    accumulate segment lengths into route arc distances

per follower and positive simulation step:
    predictedPosition = position + velocity * predictionTime
    projection = project predictedPosition onto eligible finite route segments
    resolve ties by retained route progress, not input order alone
    progress = update retained traversal state according to reacquisition policy
    target = pointAtArcDistance(progress + lookAheadDistance)
    if open route reaches its final approach zone:
        request Arrive(finalPoint)
    else:
        request velocity toward target, with optional corner-speed reduction
    return bounded acceleration
```

This outline is a specification to refine with tests, not the existing algorithm.
Continuous means a target following route segments, not a promise of a smooth
mathematical curve or a guaranteed minimum turning radius.

“Contínuo” significa usar segmentos em vez de círculos de captura; não implica
splines, curva diferenciável, limite de curvatura ou garantia de seguir a linha
exatamente. O integrador atual limita aceleração, não velocidade angular.

## Decisions before implementation / Decisões antes da implementação

1. **Reacquisition.** Define a local search window around progress plus an explicit
   full-search reset/reacquire operation for teleports. Test backward motion and
   self-intersections so nearest Euclidean segment does not silently change route
   branch. / Definir busca local e recuperação explícita após teletransporte.
2. **Progress.** Specify whether progress is monotonic in normal following and how
   loop laps are represented. / Definir progresso e contagem de voltas.
3. **Corners.** Compare a preview-based speed cap against unchanged Arrive/Seek
   guidance on the same fixtures. Select one documented rule from measured
   trajectories, without implying nonholonomic vehicle dynamics.
   / Comparar trajetórias antes de escolher uma regra de desaceleração nas curvas.
4. **Degenerate routes.** Repeated points must terminate; an all-coincident route
   should use a single-point arrival policy or a documented validation error.
   Choose and test the public contract before exposing it.
   / Definir comportamento de rotas degeneradas antes de publicar a API.

## Acceptance examples / Exemplos de aceitação

| Fixture / Cena | Independently expected result / Resultado independente |
| --- | --- |
| Segment (0,0) → (100,0), point (30,20) | Projection (30,0), local fraction 0.3, arc distance 30 |
| Same segment, point (-10,5) | Clamped projection (0,0), fraction 0 |
| Same segment, point (120,5) | Clamped projection (100,0), fraction 1 |
| Route (0,0) → (100,0) → (100,100), projected arc 60, look-ahead 60 | Target (100,20), crossing the corner by arc distance |
| Open route at final endpoint | Bounded braking; no teleportation or forced velocity zero |
| Loop near final segment | Advance through closing edge and preserve lap/progress semantics |
| Crossing route, close parallel segments | Stable selected branch under the documented progress policy |
| Repeated vertices and zero dt | No infinite loop; zero engine dt does not advance follower state |
| Two agents on one geometry | Independent follower progress; shared immutable route |
| Priority obstacle avoidance temporarily wins | Resume path according to reacquisition policy, not evaluation count |

## Delivery stages / Etapas de entrega

| Stage / Etapa | Deliverable / Entrega | Gate / Critério |
| --- | --- | --- |
| 1. Geometry / Geometria | Projection and arc-distance queries / projeção e distância acumulada | Independent numeric fixtures, boundary and degeneracy tests |
| 2. Following / Seguimento | Proposed FollowPolyline, explicit reset/reacquisition | Full trajectories, looping, immutable state and shared-route tests |
| 3. Corners / Curvas | Preview and documented speed policy | Compare overshoot, route error and arrival on fixed-step scenes |
| 4. Learning / Aprendizado | Side-by-side waypoint/continuous lab modes, Wiki diagram and CLI example | Current APIs keep old tests; new mode has widget and JS coverage |
| 5. Release / Publicação | Bilingual docs, changelog, minimum/stable SDK CI, package dry run | Only then bump version/tag/publish and verify hosted metadata |

No calendar or FPS promise is implied. Measure trajectory error and step cost
separately from rendering, with seeds, fixed dt and recorded fixtures.
Sem prazo ou FPS prometido; medir erro de trajetória e custo do passo separadamente.

## Later / Depois

Dynamic obstacles, contact resolution, vehicle kinematics and further wall-corner
work remain separate scopes. They must not silently change the meaning of this
release. / Obstáculos móveis, colisões, veículos e melhorias adicionais em paredes
ficam para escopos posteriores.
