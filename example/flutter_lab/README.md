# Steering laboratory / Laboratório de steering

[Open online / Abrir online](https://kleberandrade.github.io/steering-engine/) ·
[Learning Wiki / Wiki didática](https://github.com/kleberandrade/steering-engine/wiki)

Chapter links use `?mode=Wall%20following` or another dropdown label to initialize
the corresponding scene; missing/unknown modes fall back to Arrive.
Os links dos capítulos abrem o comportamento correspondente; valores desconhecidos
voltam para Arrive. The mode is selected at startup; reload a shared link to apply it.

Flutter >=3.35.0, Dart >=3.9.0. The core remains compatible with Dart >=3.3.0.
This app uses the source package at `../..`; no hosted publication is needed.

```sh
flutter pub get
flutter run -d chrome
flutter analyze --fatal-infos
flutter test
flutter build web --no-web-resources-cdn
```

Choose seven local behaviors, path following or either composition, move the target with a click or
drag, adjust speed/acceleration/slowing radius and toggle the vectors or trail.
Pause and Step advance exactly one 1/60-second simulation tick. Reset rewinds the
agent and seed while preserving the selected behavior and target. Pursuit and
Evade track a moving target; target dragging applies to the fixed-target modes.

The world is 1000 × 620 distance units and wraps at its edges. The core engine
does not implement wrapping. Ticker elapsed time feeds a fixed-step accumulator;
frame gaps above 0.1 seconds are capped and excess catch-up after three ticks is discarded so resuming a background tab does not
simulate a large jump. This is an educational lab, not real-time clock tracking.

Escolha o comportamento, clique ou arraste o alvo, ajuste os limites e observe
os vetores. Pause permite avançar um passo por vez; Reset reinicia o agente e a
seed. Pursuit e Evade seguem um alvo em órbita. O relógio usa passos fixos e as
bordas reposicionam o agente no lado oposto apenas neste exemplo.

Path following displays a looping, numbered route and highlights the current
waypoint. It owns a separate follower, reset along with the agent. Dragging the
free target does not edit this route. Each corner uses a 100-unit slowing radius
and a 24-unit capture radius. / O modo de trajetória exibe uma rota numerada,
destaca o waypoint atual e reinicia o percurso com Reset. Arrastar o alvo livre
não edita os waypoints desta demonstração.

## Obstacle mode / Modo de obstáculos

Select Obstacle avoidance for a three-circle scene. The violet/cyan vectors retain
their meaning. Physical circles are orange-red, expanded detection boundaries
include the 18-unit agent radius and adjustable margin, and the selected threat
is highlighted. A forward line shows max(90, speed × lookAheadTime). Priority
selects avoidance before Arrive; the target remains draggable. Destinations inside
obstacles may remain unreachable. Changing limits can create collisions: this
example has no collision solver or position corrections.

Selecione Obstacle avoidance. Ajuste a antecipação, a margem e os limites de
movimento; observe o alcance e o obstáculo destacado. A prioridade dá preferência
ao desvio e depois retoma Arrive. Não há correção física de colisões; alvos dentro
de obstáculos podem ser inalcançáveis. As mesmas regras de pausa, passo e Reset
continuam disponíveis.

## Collective modes / Modos coletivos

Separation, Alignment, Cohesion and Flocking simulate 24 agents. Every tick reads
one shared observation and replaces the entire frame. Flocking has three rule
weights and a separate target-attraction control (zero disables target seeking).
The highlighted agent's neighborhood is drawn as a ring. Pause/Step advances all
agents; Reset reproduces the initial layout and velocities from seed 42.

Position wrapping belongs to the demo; neighborhood distances are ordinary
Euclidean distances. Agents across opposite borders do not see one another as
nearby. The simulator does not resolve contacts between agents.

Os quatro modos coletivos usam 24 agentes com observação comum a cada passo.
Compare cada regra e ajuste os três pesos no Flocking. A atração pelo alvo é
separada e pode ser zerada. Pause/Step avança todo o quadro; Reset reproduz a
configuração inicial. O anel mostra a vizinhança do agente destacado. As bordas
reposicionam os agentes, mas as distâncias continuam euclidianas, sem correção
de colisões. Página, tema e desenho ficam em arquivos separados sob `lib/lab/`.

## Population, profiling and navigation

Choose 24/100/500/1000 agents and switch the spatial index on or off. The physics
HUD measures only tick computation, not paint/layout. Large populations use a
seeded distribution across the world; the original 24-agent layout stays clustered.
No more than three catch-up ticks run per frame. Leader following shows a moving
leader and its trailing target. Queue demonstrates eight lane occupants arriving
behind one another. Wall following shows finite wall geometry and a local offset
probe. See [following conventions](../../doc/following.md).

Escolha a população e compare índice espacial com busca linear. O tempo mede a
física do passo, não a renderização. As três novas demonstrações cobrem líder,
fila espacial e paredes; o seguidor de waypoints continua disponível.
