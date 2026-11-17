# Steering laboratory UI

Private Flutter package shared by the Flutter and Flame examples. It is not part
of the pure Dart engine and is not published to pub.dev.

- Original code-drawn orbit-and-heading logo and matching SVG favicons.
- Horizontally scrollable navigation on narrow screens; keyboard-focusable
  Material controls for Laboratory, Learn, Examples and Documentation.
- English and Brazilian Portuguese interface, native Material localization and
  educational content. Browser preference is shared by the two laboratories;
  disabled storage falls back to the active session. Desktop tests use a safe
  non-browser implementation.
- `IndexedStack` retains the experiment during navigation and locale changes;
  `TickerMode` suspends hidden animation. Presets deliberately reset the full
  laboratory scene. Flame demonstrates its own component integration and does
  not claim to implement every full-lab preset.
- Lessons summarize `doc/behaviors.md` and the bilingual wiki: units,
  semi-implicit Euler, Seek/Arrive, flocking and local-navigation limits.
  Documentation opens in a separate tab on the web; other targets show a
  selectable reference link. Five practical exercises conclude the Learn area.

## Validation

Resolve each example before formatting it so Dart uses its own language version.

```sh
cd example/lab_ui
flutter pub get
flutter analyze --fatal-infos
dart format --output=none --set-exit-if-changed lib
cd ../flutter_lab
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter build web --no-web-resources-cdn --base-href /steering-engine/
cd ../flame_lab
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter build web --no-web-resources-cdn --base-href /steering-engine/flame/
```

Flutter 3.50.0 / Dart 3.14.0 was used for the integrated lab validation. The core
keeps its existing Dart compatibility; Flutter remains outside `lib/`.

## Português

Pacote privado compartilhado pelos dois exemplos: identidade original,
navegação, idioma persistido no navegador e área educativa com equações,
experimentos e cinco exercícios. Trocas de seção/idioma preservam o estado;
escolher um cenário reinicia a simulação. No Flame, a experiência é a integração
por componentes; os outros cenários ficam no laboratório completo.
