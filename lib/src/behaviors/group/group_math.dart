import '../../math/vec2.dart';

/// Averages finite vectors without summing full-size inputs first.
Vec2 meanVector(Iterable<Vec2> vectors) {
  final values = vectors.toList(growable: false);
  if (values.isEmpty) return Vec2.zero;
  var mean = Vec2.zero;
  for (final value in values) {
    mean = mean + value / values.length.toDouble();
  }
  return mean;
}
