// Preserve the lab's minimum SDK while Material is re-exported on newer SDKs.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steering_engine_lab/main.dart';

SteeringPainter scene(WidgetTester tester) =>
    tester.widget<CustomPaint>(find.byKey(const Key('simulation'))).painter!
        as SteeringPainter;

void main() {
  for (final size in [
    const Size(320, 740),
    const Size(390, 844),
    const Size(740, 360),
  ]) {
    testWidgets('mobile controls at ${size.width} by ${size.height}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const SteeringLab());
      await tester.ensureVisible(find.text('Pause'));
      await tester.tap(find.text('Pause'));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('simulation')));
      await tester.tapAt(tester.getCenter(find.byKey(const Key('simulation'))));
      await tester.pump();
      expect(scene(tester).target.x, closeTo(500, .01));
      expect(scene(tester).target.y, closeTo(310, .01));
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.scrollUntilVisible(
        find.text('Continuous path'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Continuous path').last);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(find.text('Step'));
      await tester.tap(find.text('Step'));
      await tester.pump();
      expect(scene(tester).route, isNotNull);
      expect(scene(tester).projection, isNotNull);
      await tester.ensureVisible(find.text('Reset'));
      await tester.tap(find.text('Reset'));
      await tester.pump();
      expect(scene(tester).projection, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
