# Equations and conventions

Let p be position, v velocity, V maximum speed, A maximum acceleration and T the
positive response time in seconds. `limit(x, m)` preserves direction and caps
magnitude at m. The normalized zero vector is zero.

## Seek, Flee and Brake

Seek: `desired = normalize(target - p) * V`.
Flee: `desired = normalize(p - target) * V`.
Brake: `desired = zero`.
All return `limit((desired - v) / T, A)`.
A coincident target requests zero desired velocity, so a moving agent brakes.
Flee at exact overlap does not invent a direction.

## Arrive

With distance d, stop radius R0 and slowing radius R1 (R1 > R0 >= 0):
`desiredSpeed = V * clamp((d - R0) / (R1 - R0), 0, 1)`.
Multiply the target direction by desiredSpeed, then apply the response-time
formula. Inside the stop radius, braking is still bounded; velocity is not
instantly reset. This is a local controller, not an analytic stopping trajectory.

## Pursuit and Evade

Prediction time: `t = min(maxPrediction, distance / V)`; when V = 0, t = 0.
Predicted position: `target.position + target.velocity * t`.
Seek it for Pursuit or flee it for Evade. Targets are snapshots, and prediction
assumes constant target velocity; no exact intercept solution is promised.

## Wander

A private random stream updates an angle by a uniform sample in [-1, 1] multiplied
by `jitter * dt`. A circle lies `distance` units forward with the configured
`radius`. Its angular point is sought. Heading follows velocity, with +X as the
stationary fallback. Angle wraps modulo 2π. Zero dt neither changes angle nor
consumes randomness. Own an instance per agent and evaluate it once per step.

## Composition

WeightedBlend sums `weight * acceleration` then caps to A. No normalization.
PrioritySteering selects the first magnitude strictly greater than epsilon, then
caps it to A. Empty lists return zero; zero-weight entries are never called.
Both copy input lists. Custom behavior instances may themselves own mutable state.

## Integration and numeric boundaries

`a = limit(behavior.calculate(agent, dt), A)`

`vNext = limit(v + a * dt, V)`

`pNext = p + vNext * dt`

This is semi-implicit Euler. No internal substeps, collision response, drag or
mass are modeled. `dt == 0` returns the same snapshot without evaluation.
All numeric configuration is checked outside asserts. Finite vectors must also
have representable magnitude. Arithmetic overflow throws rather than creating
nonfinite state. Extremely large or tiny scales are not a promise of physical
accuracy; use a sensible, consistent coordinate scale and fixed steps.

## Static obstacle avoidance / Desvio de obstáculos estáticos

See [the bilingual geometry guide](obstacle_avoidance.md) for expanded circle
radii, ray entry selection, overlap response, braking and numerical limits.
Consulte o guia bilíngue para as equações e limitações do desvio circular.
