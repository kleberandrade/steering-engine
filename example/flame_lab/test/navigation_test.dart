// Keep compatibility with the minimum Flutter SDK.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steering_flame_example/main.dart';
import 'package:steering_flame_example/steering_game.dart';
import 'package:steering_lab_ui/steering_lab_ui.dart';

void main() {
  testWidgets('Flame game survives learning navigation and locale changes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: const LabShell(flame: true, laboratory: FlameExample()),
      ),
    );
    await tester.pump();
    final before = tester
        .widget<GameWidget<SteeringDemoGame>>(
          find.byType(GameWidget<SteeringDemoGame>),
        )
        .game;
    await tester.tap(find.text('Learn'));
    await tester.pump();
    expect(find.text('Motion from small rules'), findsOneWidget);
    expect(before?.paused, isTrue);
    await tester.tap(find.byKey(const Key('language')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Português').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laboratório'));
    await tester.pump();
    final after = tester
        .widget<GameWidget<SteeringDemoGame>>(
          find.byType(GameWidget<SteeringDemoGame>),
        )
        .game;
    expect(identical(before, after), isTrue);
    expect(after?.paused, isFalse);
    expect(find.text('Reiniciar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
