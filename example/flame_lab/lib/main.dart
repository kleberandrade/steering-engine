import 'package:flame/game.dart';
// Keep compatibility with Flutter versions that do not re-export Material.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:steering_lab_ui/steering_lab_ui.dart';
import 'package:steering_engine/steering_engine.dart' as steering;
import 'steering_game.dart';

void main() => runApp(
  MaterialApp(
    title: 'Steering Engine · Flame Lab',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff6ae4d4),
        brightness: Brightness.dark,
      ),
    ),
    home: const LabShell(flame: true, laboratory: FlameExample()),
  ),
);

class FlameExample extends StatefulWidget {
  const FlameExample({super.key});
  @override
  State<FlameExample> createState() => _FlameExampleState();
}

class _FlameExampleState extends State<FlameExample> {
  final _game = SteeringDemoGame();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled) {
      _game.resumeEngine();
    } else {
      _game.pauseEngine();
    }
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xff101a29),
    child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              tr(context, 'Steering Engine + Flame · Tap to move the target'),
              style: const TextStyle(color: Color(0xffd9e4f3), fontSize: 18),
            ),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1000 / 620,
                child: LayoutBuilder(
                  builder: (context, constraints) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (event) {
                      _game.target = steering.Vec2(
                        event.localPosition.dx / constraints.maxWidth * 1000,
                        event.localPosition.dy / constraints.maxHeight * 620,
                      );
                    },
                    child: GameWidget(game: _game),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: OutlinedButton(
              onPressed: _game.reset,
              child: Text(tr(context, 'Reset')),
            ),
          ),
        ],
      ),
    ),
  );
  @override
  void dispose() {
    _game.dispose();
    super.dispose();
  }
}
