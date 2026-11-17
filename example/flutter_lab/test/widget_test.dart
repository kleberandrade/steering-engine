// Preserve Flutter 3.35 compatibility while newer SDKs re-export Material here.
// ignore: deprecated_member_use
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
  testWidgets(
      'obstacle mode exposes geometry and responds to target interaction',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SteeringLab());
    await tester.tap(find.text('Pause'));
    await tester.pump();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('Obstacle avoidance').last);
    await tester.tap(find.text('Obstacle avoidance').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(scene(tester).avoidance!.obstacles.length, 3);
    expect(scene(tester).avoidance!.agentRadius, 18);
    expect(scene(tester).avoidance!.safetyMargin, 10);
    final before = scene(tester).agent.position;
    await tester.tap(find.text('Step'));
    await tester.pump();
    expect(scene(tester).agent.position.x, greaterThan(before.x));
    await tester.tapAt(tester.getCenter(find.byKey(const Key('simulation'))));
    await tester.pump();
    expect(scene(tester).target.x, closeTo(500, 0.01));
    expect(scene(tester).target.y, closeTo(310, 0.01));
    expect(tester.takeException(), isNull);
  });
  testWidgets('flocking advances every agent from a shared frame and resets',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SteeringLab());
    await tester.tap(find.text('Pause'));
    await tester.pump();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('Flocking').last);
    await tester.tap(find.text('Flocking').last);
    await tester.pump(const Duration(milliseconds: 300));
    final initial = scene(tester).flock.map((a) => a.position).toList();
    expect(initial.length, 24);
    await tester.tap(find.text('Step'));
    await tester.pump();
    for (var i = 0; i < initial.length; i++) {
      expect(scene(tester).flock[i].position, isNot(initial[i]));
    }
    final paused = scene(tester).flock[1].position;
    await tester.pump(const Duration(milliseconds: 100));
    expect(scene(tester).flock[1].position, paused);
    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(scene(tester).flock.map((a) => a.position).toList(), initial);
    expect(tester.takeException(), isNull);
  });
  testWidgets('population and spatial controls update the measured flock scene',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SteeringLab());
    await tester.tap(find.text('Pause'));
    await tester.pump();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('Flocking').last);
    await tester.tap(find.text('Flocking').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('100').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(scene(tester).flock.length, 100);
    await tester.tap(find.text('Step'));
    await tester.pump();
    expect(find.textContaining('ms'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
