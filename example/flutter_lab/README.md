# Steering laboratory / Laboratório de steering

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
frame gaps above 0.1 seconds are discarded so resuming a background tab does not
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
