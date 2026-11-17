import 'agent.dart';
import 'vec2.dart';

/// Produces acceleration in distance units per second squared.
///
/// Implementations must accept finite nonnegative elapsed time in seconds. The engine
/// caps the returned vector before integrating; custom implementations may
/// return an acceleration above the agent's limit.
abstract interface class SteeringBehavior {
  /// Evaluates a snapshot; [dt] is elapsed simulation time in seconds.
  Vec2 calculate(SteeringAgent agent, double dt);
}
