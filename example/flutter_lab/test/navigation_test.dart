// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steering_engine_lab/main.dart';

void main() {
  testWidgets('navigation and language preserve a paused experiment', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SteeringLab());
    await tester.tap(find.text('Pause'));
    await tester.pump();
    final before =
        (tester
                    .widget<CustomPaint>(find.byKey(const Key('simulation')))
                    .painter!
                as SteeringPainter)
            .agent
            .position;
    await tester.tap(find.text('Learn'));
    await tester.pump();
    expect(find.text('Motion from small rules'), findsOneWidget);
    await tester.tap(find.byKey(const Key('language')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Português').last);
    await tester.pumpAndSettle();
    expect(find.text('Movimento a partir de pequenas regras'), findsOneWidget);
    await tester.tap(find.text('Laboratório'));
    await tester.pump();
    expect(find.text('Continuar'), findsOneWidget);
    final after =
        (tester
                    .widget<CustomPaint>(find.byKey(const Key('simulation')))
                    .painter!
                as SteeringPainter)
            .agent
            .position;
    expect(after, before);
    expect(tester.takeException(), isNull);
  });
  testWidgets('mobile navigation opens translated presets and documentation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SteeringLab());
    await tester.ensureVisible(find.text('Examples'));
    await tester.tap(find.text('Examples'));
    await tester.pump();
    await tester.tap(find.text('Flocking'));
    await tester.pump();
    final painter =
        tester.widget<CustomPaint>(find.byKey(const Key('simulation'))).painter!
            as SteeringPainter;
    expect(painter.flock.length, 24);
    await tester.tap(find.byKey(const Key('language')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Português').last);
    await tester.pump();
    expect(find.text('Pausar'), findsOneWidget);
    expect(find.textContaining('Velocidade máxima'), findsOneWidget);
    final docs = find.text('Documentação');
    await tester.ensureVisible(docs);
    await tester.tap(docs);
    await tester.pump();
    expect(find.text('Documentação e código'), findsOneWidget);
    expect(find.textContaining('doc/behaviors.md'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
