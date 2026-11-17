# 0.2.0 — continuous path implementation / implementação contínua

The four implementation stages are complete in source; hosted publication is
verified separately. / Os quatro itens estão implementados na fonte; publicação
hospedada é uma etapa separada.

| Stage / Etapa | Result / Resultado | Evidence / Evidência |
| --- | --- | --- |
| 1. Geometry / Geometria | Immutable PolylinePath, finite PathProjection, cumulative arc sampling | Numeric L-route and boundary fixtures; repeated-edge/degeneracy validation |
| 2. Following / Seguimento | FollowPolyline, prediction, monotonic forward windows, laps, reset and global reacquisition | Public state, crossing-branch and independent-follower tests |
| 3. Corners / Curvas | Configurable preview speed ratio from tangent angle and corner distance | Independent 90° math and paired trajectories with/without preview |
| 4. Learning / Aprendizado | Continuous lab mode, projection and arc target, Wiki chapter/diagram, VM/JS CLI | Widget scenario, docs/deep-link coverage and CI |

## Compatibility / Compatibilidade

`FollowPath` and `SteeringPath` retain their capture-radius contracts, including
single-point routes. New `PolylinePath` requires at least one nonzero edge;
repeated consecutive vertices are skipped in its geometry. Closing edges are
included for loops. Immutable geometry can be shared; follower state cannot.

FollowPolyline adquire globalmente na primeira avaliação positiva. Depois projeta
apenas em uma janela adiante, com progresso monotônico e voltas acumuladas.
`reacquire(agent)` projeta a posição real globalmente e reinicia voltas; `reset()`
limpa estado para a próxima aquisição. Marcha a ré não retrocede o progresso.

## Settled design choices / Decisões adotadas

- First acquisition/global reacquisition uses earliest-edge order on equal
  geometric distance. Subsequent acquisition searches a forward arc window,
  splitting at loop seams and considering at most one lap. Close branches inside
  that window can still compete; this is not universal branch disambiguation.
- Corner preview uses `r = minRatio + (1-minRatio)*(1+cos(turn))/2`, linearly
  relaxing to one at the preview boundary. Zero preview disables it. It caps
  desired speed, not actual instantaneous speed or angular velocity.
- Open-route target sampling clamps at the endpoint. When look-ahead reaches it,
  final desired speed follows the existing Arrive distance profile.
- Direct zero-dt follower evaluation returns zero without mutating state;
  engine zero-dt evaluation remains an identical-snapshot no-op.

## Acceptance fixtures / Cenas de aceitação

Projection of (30,20) onto (0,0)→(100,0) is (30,0), fraction .3, arc distance 30.
For the L-route (0,0)→(100,0)→(100,100), arc 60 + look-ahead 60 yields (100,20).
Restricted arc projection prevents a remote branch from winning outside the window.

In the recorded L-route comparison (V=40, A=100, dt=1/60, 2400 steps), corner
preview 35 reduced peak speed within 20 units of the vertex from 39.9721 to
37.7693. Maximum route distance increased from 4.8020 to 4.9133. Both final
arrival distances were below 1.0. These are fixture measurements, not universal
quality promises. Run `dart run example/polyline_following.dart` to reproduce.

A antecipação reduziu a velocidade perto da curva, mas não melhorou o erro máximo
nessa cena. Não promete splines, curvatura limitada, aderência à linha, colisões
ou dinâmica de veículos. Veja [o capítulo](wiki/Continuous-Path.md).

## Release gate / Publicação

The [0.2.0 audit](release_0.2.0.md) separates local tests, remote CI, GitHub release,
Pages deployment and actual pub.dev upload. Do not infer one from another.

Dynamic obstacles, contact resolution, vehicle kinematics and further wall-corner
work remain separate future scopes. / Obstáculos móveis, colisões, veículos e
melhorias adicionais em paredes permanecem fora desta versão.
