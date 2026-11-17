# Steering Engine + Flame

A separate Flame 1.38.x app demonstrating 24 shared-frame agents, fixed-step
steering and PositionComponent coordinate mapping. Requires Flutter >=3.47 and
Dart >=3.11. The core package remains pure Dart >=3.3.

```sh
flutter pub get
flutter run -d chrome
flutter analyze --fatal-infos
flutter test
flutter build web --no-web-resources-cdn
```

Tap the scene to change the target; use Reset to restore initial snapshots.
See [integration details](../../doc/flame.md). No collision solver is included.

Exemplo separado com 24 agentes: toque muda o alvo e Reset reinicia o cenário.
Flame renderiza os componentes enquanto steering_engine calcula o movimento.
