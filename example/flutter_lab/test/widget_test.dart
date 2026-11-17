import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steering_engine_lab/main.dart';

SteeringPainter scene(WidgetTester tester) =>
    tester.widget<CustomPaint>(find.byKey(const Key('simulation'))).painter!
        as SteeringPainter;

void main() {
  testWidgets('simulates, pauses, single-steps and resets the public engine',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SteeringLab());
    final initial = scene(tester).agent.position;
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 100));
    expect(scene(tester).agent.position.x, greaterThan(initial.x));
    await tester.tap(find.text('Pause'));
    await tester.pump();
    final paused = scene(tester).agent.position;
    await tester.pump(const Duration(milliseconds: 100));
    expect(scene(tester).agent.position.x, paused.x);
    await tester.tap(find.text('Step'));
    await tester.pump();
    expect(scene(tester).agent.position.x, greaterThan(paused.x));
    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(scene(tester).agent.position.x, initial.x);
    await tester.tapAt(tester.getCenter(find.byKey(const Key('simulation'))));
    await tester.pump();
    expect(scene(tester).target.x, closeTo(500, 0.01));
    expect(scene(tester).target.y, closeTo(310, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow layout and behavior selection remain usable',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SteeringLab());
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Wander').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(
        find.text(
            'A seeded random stream changes a local target ahead of the agent.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
