/// Supported chapter-link modes, in the laboratory dropdown order.
const labModes = [
  'Arrive',
  'Seek',
  'Flee',
  'Pursuit',
  'Evade',
  'Wander',
  'Brake',
  'Path following',
  'Continuous path',
  'Leader following',
  'Queue',
  'Wall following',
  'Obstacle avoidance',
  'Separation',
  'Alignment',
  'Cohesion',
  'Flocking',
  'Weighted blend',
  'Priority'
];

/// Reads a shareable mode link; unsupported values keep the default scene.
String modeFromUri(Uri uri) {
  final requested = uri.queryParameters['mode'];
  return labModes.contains(requested) ? requested! : 'Arrive';
}
