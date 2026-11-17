import '../../composition/weighted_behavior.dart';
import '../../composition/weighted_blend.dart';
import '../../core/agent.dart';
import '../../core/steering_behavior.dart';
import '../../math/vec2.dart';
import '../../perception/agent_neighborhood.dart';
import 'alignment.dart';
import 'cohesion.dart';
import 'separation.dart';

/// Composes separation, alignment and cohesion using the weighted blend contract.
///
/// Rebuild with a shared neighborhood each frame, then compute all new states
/// from the old snapshots before replacing the population.
final class Flocking implements SteeringBehavior {
  /// Creates three local rules with finite nonnegative, unnormalized weights.
  ///
  /// Radii and alignment response time must be positive. Zero weights disable
  /// rule evaluation. No collision handling or global destination is implied.
  Flocking(this.neighborhood,
      {double separationRadius = 25,
      double neighborRadius = 80,
      double responseTime = 0.25,
      this.separationWeight = 1.5,
      this.alignmentWeight = 1,
      this.cohesionWeight = 1})
      : separation = Separation(neighborhood, radius: separationRadius),
        alignment = Alignment(neighborhood,
            radius: neighborRadius, responseTime: responseTime),
        cohesion = Cohesion(neighborhood, radius: neighborRadius) {
    _blend = WeightedBlend([
      WeightedBehavior(separation, weight: separationWeight),
      WeightedBehavior(alignment, weight: alignmentWeight),
      WeightedBehavior(cohesion, weight: cohesionWeight),
    ]);
  }

  /// Shared snapshots for this frame.
  final AgentNeighborhood neighborhood;

  /// Component rule, also available for independent inspection.
  final Separation separation;

  /// Component rule, also available for independent inspection.
  final Alignment alignment;

  /// Component rule, also available for independent inspection.
  final Cohesion cohesion;

  /// Relative repulsion weight, without automatic normalization.
  final double separationWeight;

  /// Relative velocity matching weight.
  final double alignmentWeight;

  /// Relative attraction weight.
  final double cohesionWeight;

  late final WeightedBlend _blend;

  @override
  Vec2 calculate(SteeringAgent agent, double dt) => _blend.calculate(agent, dt);
}
