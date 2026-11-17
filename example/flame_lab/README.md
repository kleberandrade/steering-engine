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

## Navigation and learning / Navegação e aprendizado

Use the top navigation to switch between the experiment, lessons, examples and
source documentation. English and Brazilian Portuguese preserve the active
experiment; browser storage remembers the preference when available. The
[shared UI guide](../lab_ui/README.md) explains validation and maintenance.

Use a navegação superior para alternar entre experimento, lições, exemplos e
documentação. O idioma inglês/português preserva o experimento em andamento.

![Flame laboratory with Portuguese navigation and original Steering mark](../../doc/screenshots/flame-mobile-pt-br.jpg)
