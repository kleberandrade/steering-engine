import '../core/agent.dart';
import '../core/validation.dart';
import 'spatial_hash.dart';

/// A shared, immutable snapshot of agents observed during one simulation frame.
final class AgentNeighborhood {
  /// Copies agents, removing repeated references while preserving input order.
  AgentNeighborhood(Iterable<SteeringAgent> agents)
      : agents =
            List.unmodifiable(Set<SteeringAgent>.identity()..addAll(agents)),
        _grid = null;

  /// Builds an optional grid. Unsafe coordinate scales transparently fall back
  /// to a linear scan. Exact filtering and input order match the linear API.
  factory AgentNeighborhood.spatial(Iterable<SteeringAgent> agents,
      {double cellSize = 80}) {
    positive(cellSize, 'cellSize');
    final copied = List<SteeringAgent>.unmodifiable(
        Set<SteeringAgent>.identity()..addAll(agents));
    return AgentNeighborhood._(copied, SpatialHash.build(copied, cellSize));
  }

  AgentNeighborhood._(this.agents, this._grid);
  final SpatialHash? _grid;

  /// Whether this snapshot owns a usable spatial grid. Large queries may still
  /// use a linear fallback when traversing cells would be more expensive.
  bool get usesSpatialIndex => _grid != null;

  /// Unique immutable agent snapshots in observation order.
  final List<SteeringAgent> agents;

  /// Returns agents within an inclusive radius, excluding [observer] by identity.
  ///
  /// A distinct snapshot at the same position is still a neighbor. Pass the
  /// actual observer snapshot from this frame, not a copy, to exclude itself.
  /// Both strategies use ordinary Euclidean distance, without world wrapping.
  List<SteeringAgent> neighborsFor(SteeringAgent observer,
      {required double radius}) {
    nonNegative(radius, 'radius');
    final candidates = _grid?.candidates(observer.position, radius);
    final observed =
        candidates == null ? agents : candidates.map((index) => agents[index]);
    return List.unmodifiable(observed.where((other) =>
        !identical(other, observer) &&
        (other.position - observer.position).length <= radius));
  }
}
