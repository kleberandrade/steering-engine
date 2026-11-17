import 'package:flutter_test/flutter_test.dart';
import 'package:steering_engine_lab/lab/lab_modes.dart';

void main() {
  test('chapter links select all supported modes and unknown modes fall back', () {
    for (final mode in labModes) {
      final uri =
          Uri.https('example.test', '/steering-engine/', {'mode': mode});
      expect(modeFromUri(uri), mode);
    }
    expect(modeFromUri(Uri.parse('https://example.test/')), 'Arrive');
    expect(
        modeFromUri(Uri.parse('https://example.test/?mode=unknown')), 'Arrive');
    expect(modeFromUri(Uri.parse('https://example.test/?mode=')), 'Arrive');
    expect(
        modeFromUri(Uri.parse('https://example.test/?mode=Wall%20following')),
        'Wall following');
  });
}
