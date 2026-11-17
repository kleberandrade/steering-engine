/// Requires a finite, nonnegative value.
void nonNegative(double value, String name) {
  if (!value.isFinite || value < 0) {
    throw ArgumentError.value(value, name, 'Must be finite and nonnegative');
  }
}

/// Requires a finite, strictly positive value.
void positive(double value, String name) {
  if (!value.isFinite || value <= 0) {
    throw ArgumentError.value(value, name, 'Must be finite and positive');
  }
}
