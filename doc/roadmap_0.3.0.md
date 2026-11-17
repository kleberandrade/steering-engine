# 0.3.0 — route tracking quality / qualidade do seguimento

**Plan only: not implemented, tagged or published. / Apenas planejamento.**

0.2.0 supplies continuous polyline guidance and optional corner preview. Its
recorded L-route slowed near the corner but slightly increased maximum tracking
error. 0.3.0 should improve that measured tradeoff while preserving both existing
followers. No version bump or date is implied by this plan.

A próxima etapa parte da medição existente, não de uma promessa de suavidade.
FollowPath e FollowPolyline mantêm seus contratos atuais; mudanças de política
precisam de modo explícito ou opção compatível e de comparação reproduzível.

## Proposed scope / Escopo proposto

| Stage / Etapa | Deliverable / Entrega | Acceptance / Aceitação |
| --- | --- | --- |
| 1. Baseline / Referência | Reproducible route-quality harness | Same fixtures, fixed dt, initial states and recorded numeric results |
| 2. Tracking / Seguimento | Evaluate cross-track correction and speed-preview alternatives | Lower maximum/RMS route distance on declared fixtures without arrival or lap regressions |
| 3. Reacquisition / Recuperação | Explicit optional policy for large deviations | Deterministic recovery on teleports, nearby branches and self-intersections; current default preserved |
| 4. Teaching / Aprendizado | Lab comparisons and bilingual diagrams | Pause/step, mobile controls, CLI/JS and source/publication evidence |

## Measurement contract / Contrato de medição

Use straight, right-angle, acute, near-reversal, closed triangle and crossing
routes. Include both off-route starts and moderate external displacement. Run
with fixed dt=1/60 and repeat at 1/120 to assess sensitivity; matching results
across time steps are not assumed.

Record at least maximum and RMS Euclidean distance to eligible route segments,
arrival distance/speed for open routes, lap count for closed routes, number of
reacquisitions, peak speed near corners and physics-step time. Global nearest
route distance alone can hide wrong-branch tracking; record progress/segment
selection as a separate outcome.

Registre métricas de trajetória e de ramo escolhido separadamente; medir apenas
a distância à linha pode esconder um salto indevido em cruzamentos. Tempo do
passo não é FPS e deve ser separado de renderização/layout.

## Baseline / Referência da 0.2.0

`dart run example/polyline_following.dart` uses the 100+100 L-route, V=40, A=100,
2400 steps and look-ahead=15. The recorded VM measurements were:

| Metric / Métrica | Preview disabled / desativado | Preview 35 |
| --- | --- | --- |
| Peak speed within 20 units of corner | 39.9721 | 37.7693 |
| Maximum distance to the route | 4.8020 | 4.9133 |
| Final destination distance | 0.9752 | 0.9748 |

Treat these as fixture-specific evidence, not universal performance or quality
claims. A new controller must be evaluated against both configurations.

## Compatibility decisions / Decisões de compatibilidade

- Keep existing capture-radius FollowPath and existing FollowPolyline defaults.
- Share only immutable route geometry, never per-follower progress.
- Preserve zero-dt no-op, finite runtime validation, acceleration/speed caps,
  minimum Dart SDK and VM/JS support.
- Expose inspection without a second stateful calculate call for rendering.
- Any automatic recovery is opt-in with an explicit threshold and tie policy;
  preserve manual reset/reacquire and document lap semantics.

## Out of scope / Fora do escopo

No dynamic-obstacle solver, rigid-body contacts, wheel dynamics, global
pathfinding, mandatory Flutter/Flame dependency, spline promise or guaranteed
minimum turning radius. These require their own design and validation.

Sem resolução de colisões, dinâmica de veículos ou planejamento global nesta
etapa. Uma linha visual mais suave não substitui critérios numéricos de controle.

## Release gate / Critério de release

Public-API tests must independently specify geometry and controller behavior.
Keep previous tests, add whole trajectories for each new policy and compare VM/JS.
Update the lab, Wiki and both READMEs, pass minimum/stable CI and package dry run,
then publish a matching new version/tag through the documented release flow.
Hosted package availability and publisher ownership are verified separately.
