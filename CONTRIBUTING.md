# Contributing / Contribuindo

Use semantic commits (`feat:`, `fix:`, `docs:`, `chore:`). Keep public APIs
documented with Dartdoc and user guides synchronized in English and Portuguese.
Keep the core pure Dart without runtime dependencies, IO, Flutter or global state.
Validate configuration in normal runtime code. Test via the public entry point,
using independently calculated expectations and complete movement scenarios.

## Checks

```sh
dart pub get
dart format --output=none --set-exit-if-changed lib test example
dart analyze --fatal-infos
dart test
dart run example/steering_engine_example.dart
dart run example/composition.dart
dart run example/path_following.dart
dart run example/obstacle_avoidance.dart
dart run example/flocking.dart
dart compile js example/steering_engine_example.dart -o /tmp/steering-example.js
node /tmp/steering-example.js
dart compile js example/path_following.dart -o /tmp/steering-path.js
node /tmp/steering-path.js
dart compile js example/obstacle_avoidance.dart -o /tmp/steering-obstacles.js
node /tmp/steering-obstacles.js
dart compile js example/flocking.dart -o /tmp/steering-flocking.js
node /tmp/steering-flocking.js
dart pub publish --dry-run
cd example/flutter_lab
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter build web --no-web-resources-cdn
```

CI resolves dependencies for the minimum supported Dart SDK and stable; the lock
files are ignored because this is a reusable package and the lab uses a path
source. Add regressions before behavioral fixes, preserve released notes, and
record material decisions in `doc/engineering_log.md`. Publication and tagging
are separate release steps; never claim a hosted release from a source version.

Use commits semânticos, mantenha os guias bilíngues e execute as verificações.
Preserve o núcleo independente de Flutter e valide entradas sem depender de
asserts. Atualize o changelog e não confunda código no GitHub com publicação.

Contributions use the MIT license.
