# Flame integration / Integração com Flame

The core has no Flame or Flutter dependency. The dedicated example is in
[example/flame_lab](../example/flame_lab/README.md), with its own pubspec.
It uses Flame 1.38.x, Flutter >=3.47 and Dart >=3.11; the core still supports
Dart >=3.3. The regular Flutter lab supports its existing minimum independently.

```sh
cd example/flame_lab
flutter pub get
flutter run -d chrome
flutter analyze --fatal-infos
flutter test
flutter build web --no-web-resources-cdn
```

The example separates a `SteeringDemoGame` from its `AgentView` components. Each
fixed step builds one shared spatial observation, runs flocking plus a small
arrival contribution, then copies Vec2 coordinates and velocity angle into
Flame's Vector2-based position/angle. Components render the state; they do not
calculate a second independent movement. Tap to move the destination; Reset
restores the initial population. The camera uses a 1000 × 620 fixed-resolution
world matching the gesture mapping.

`update(dt)` receives seconds from Flame and feeds a fixed 1/60-second accumulator.
At most three catch-up steps run per update; excess time is discarded. This keeps
the demo responsive but is not real-time clock tracking under load. The example
has no collision solver, assets, sprite sheets, network or platform plugin.

Use an import prefix to avoid collisions with Flutter names:

```dart
import 'package:steering_engine/steering_engine.dart' as steering;
```

See official [FlameGame](https://docs.flame-engine.org/latest/flame/game.html),
[PositionComponent](https://docs.flame-engine.org/latest/flame/components/position_component.html)
and [GameWidget](https://docs.flame-engine.org/latest/flame/game_widget.html)
documentation for lifecycle and coordinate conventions.

## Português

O exemplo é um app separado; Flame não vira dependência do núcleo. A simulação
usa um único snapshot por quadro e transfere posição/ângulo aos componentes.
O relógio do Flame alimenta passos fixos em segundos, com limite de recuperação
para manter a interação responsiva. A câmera e o mapeamento do toque usam o mesmo
mundo de 1000 × 620. Toque muda o destino; Reset reinicia o grupo.

Os testes verificam avanço dos snapshots e cópia dos transformadores. Análise,
testes e build web são executados em um job CI próprio com Flutter estável.
