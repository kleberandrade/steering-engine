import '../core/agent.dart';
import '../math/vec2.dart';

/// Internal uniform-grid acceleration structure preserving snapshot ordinals.
final class SpatialHash {
  SpatialHash._(this.cellSize, this._cells);

  /// Spatial cell width in coordinate units.
  final double cellSize;
  final Map<(int, int), List<int>> _cells;
  static const _safeCoordinate = 1125899906842624.0;

  /// Returns null when cell coordinates cannot be represented safely on JS/VM.
  static SpatialHash? build(List<SteeringAgent> agents, double cellSize) {
    final cells = <(int, int), List<int>>{};
    for (var i = 0; i < agents.length; i++) {
      final x = agents[i].position.x / cellSize;
      final y = agents[i].position.y / cellSize;
      if (!_safe(x) || !_safe(y)) return null;
      (cells[(x.floor(), y.floor())] ??= []).add(i);
    }
    return SpatialHash._(cellSize, cells);
  }

  static bool _safe(double coordinate) =>
      coordinate.isFinite && coordinate.abs() < _safeCoordinate;

  /// Returns sorted candidate ordinals, or null to request a linear fallback.
  List<int>? candidates(Vec2 center, double radius) {
    if (_cells.isEmpty) return const [];
    final x = center.x / cellSize;
    final y = center.y / cellSize;
    final r = radius / cellSize;
    final padding = (x.abs() + y.abs() + r + 1) * 1e-12;
    final bounds = [
      x - r - padding,
      x + r + padding,
      y - r - padding,
      y + r + padding
    ];
    if (!bounds.every(_safe)) return null;
    // Scale-aware padding protects rounding at cell boundaries without scanning
    // an extra full ring of cells in ordinary scenes.
    final minX = bounds[0].floor();
    final maxX = bounds[1].floor();
    final minY = bounds[2].floor();
    final maxY = bounds[3].floor();
    final width = maxX - minX + 1;
    final height = maxY - minY + 1;
    if (width > (_cells.length * 4) ~/ height) return null;
    final result = <int>[];
    for (var i = minX; i <= maxX; i++) {
      for (var j = minY; j <= maxY; j++) {
        final entries = _cells[(i, j)];
        if (entries != null) result.addAll(entries);
      }
    }
    result.sort();
    return result;
  }
}
