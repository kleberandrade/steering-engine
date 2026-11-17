import 'agent.dart';
import 'behavior.dart';
import 'validation.dart';

/// Integrates bounded acceleration and velocity using semi-implicit Euler.
final class SteeringEngine {
  /// Creates a stateless integrator.
  const SteeringEngine();

  /// Returns a new state after [dt] seconds. Zero is a no-op without evaluation.
  ///
  /// Use small fixed steps (for example 1/60 s). Large steps can overshoot
  /// targets; this integrator does not perform collision detection or substeps.
  SteeringAgent step(
      SteeringAgent agent, SteeringBehavior behavior, double dt) {
    nonNegative(dt, 'dt');
    if (dt == 0) return agent;
    final acceleration =
        behavior.calculate(agent, dt).limited(agent.maxAcceleration);
    final velocity =
        (agent.velocity + acceleration * dt).limited(agent.maxSpeed);
    return agent.copyWith(
        position: agent.position + velocity * dt, velocity: velocity);
  }
}
