# Path following / Seguindo trajetórias

SteeringPath copies a nonempty waypoint list and may be shared by agents.
FollowPath owns traversal: keep one follower per agent and preserve it between
frames. Use a nonlooping path to arrive at the last point or `loop: true` to
return from the last point to the first.

Each positive-dt calculation advances over waypoints within `waypointRadius`,
then applies Arrive to the active point. No more than n−1 transitions occur per
evaluation, including coincident loop points. Zero dt does not change traversal.
The last point of an open route remains the destination; the agent brakes inside
`stopRadius`. `waypointRadius` must exceed `stopRadius`, allowing a slowing agent
to enter an intermediate capture region and advance. `slowingRadius` must also
exceed `stopRadius`.

This is ordered capture-radius following. It does not project onto segments,
recognize crossed waypoints between frames, avoid obstacles or solve mazes.
Large time steps and tight curves may miss a capture region. Tune speed,
acceleration, radii and time step together. Duplicate points are allowed and
skipped with bounded work; a single-point loop behaves like Arrive.

`waypointIndex` and `currentTarget` expose traversal for debugging; `reset()`
rewinds it. Replacing a route requires constructing a new follower. A blend or
priority selector can contain a follower; disabled or unselected entries do not
advance. Like Wander, do not sample a follower twice to render debug vectors.

The [CLI example](../example/path_following.dart) traverses a right-angle route,
checks its final region and runs on both Dart VM and JavaScript. The Flutter lab
shows numbered waypoints and the active target on a repeating route.

## Português

SteeringPath copia uma lista não vazia e pode ser compartilhada. FollowPath
mantém o progresso: preserve uma instância por agente entre os frames. Rotas
abertas chegam ao último ponto; `loop: true` retorna ao primeiro ponto.

A cada avaliação com dt positivo, pontos dentro de `waypointRadius` são visitados
e o próximo destino usa Arrive. O processamento avança no máximo n−1 posições
por chamada, evitando ciclos infinitos quando há pontos coincidentes. dt zero
não altera o progresso. O último ponto permanece como destino em uma rota aberta.

Os raios de captura e desaceleração precisam ser maiores que `stopRadius`.
Consulte `waypointIndex`, `currentTarget` e `reset()` para depurar ou reiniciar.
O algoritmo usa captura por distância: não projeta o agente nos segmentos,
não detecta automaticamente cruzamentos entre frames e não desvia de obstáculos.
Ajuste velocidade, aceleração, raios e passo de tempo para curvas apertadas.

No laboratório, os pontos numerados formam uma rota repetida e o anel dourado
indica o destino atual. Arrastar o alvo livre não altera essa rota. O exemplo CLI
executa uma rota aberta e verifica a chegada ao último ponto.
