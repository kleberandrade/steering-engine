# Getting started

## Learning path

New to steering? Start with [Foundations](wiki/Foundations.md), then follow the
[illustrated learning guide](wiki/Home.md) or the
[GitHub Wiki](https://github.com/kleberandrade/steering-engine/wiki). Every behavior
has pseudocode, diagrams, tuning examples and implementation limits.

1. Add the local path dependency from the README and run `dart pub get`.
2. Create a `SteeringAgent` with a position, maximum speed and acceleration.
3. Choose a behavior. Start with `Arrive` to observe approach and braking.
4. Call `SteeringEngine.step` with a small time step in **seconds**.
5. Store the returned snapshot and draw its position.

The engine does not own a clock, renderer or world. In Flutter, accumulate elapsed
Ticker time and execute fixed simulation steps, as the lab does. In Flame, use
`update(double dt)` to feed your accumulator and copy the resulting position to
the component. There is no required Flame dependency.

## Common mistakes

| Symptom | Check |
| --- | --- |
| Motion is too fast | Convert milliseconds to seconds |
| Agent passes the target | Use Arrive instead of Seek; reduce step size |
| Wander appears coupled across agents | Create a separate Wander instance for each |
| Pursuit chases an old location | Rebuild with the current target snapshot |
| A blend never settles | Its Wander contribution may continually request movement |
| Agent moves despite zero acceleration | Existing velocity remains; zero acceleration is coasting |

Run `dart run example/steering_engine_example.dart` and
`dart run example/composition.dart`. Try the Flutter lab for vectors and trails.
