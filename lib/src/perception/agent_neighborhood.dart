import '../core/agent.dart';
import '../core/validation.dart';

/// A shared, immutable snapshot of agents observed during one simulation frame.
final class AgentNeighborhood {
  /// Copies agents, removing repeated references while preserving input order.
  AgentNeighborhood(Iterable<SteeringAgent> agents)
      : agents =
            List.unmodifiable(Set<SteeringAgent>.identity()..addAll(agents));

  /// Unique immutable agent snapshots in observation order.
  final List<SteeringAgent> agents;

  /// Returns agents within an inclusive radius, excluding [observer] by identity.
  ///
  /// A distinct snapshot at the same position is still a neighbor. Pass the
  /// actual observer snapshot from this frame, not a copy, to exclude itself.
  /// This linear scan uses ordinary Euclidean distance, without world wrapping.
  List<SteeringAgent> neighborsFor(SteeringAgent observer,
      {required double radius}) {
    nonNegative(radius, 'radius');
    return List.unmodifiable(agents.where((other) =>
        !identical(other, observer) &&
        (other.position - observer.position).length <= radius));
  }
}
