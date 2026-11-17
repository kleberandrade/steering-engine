import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:steering_engine/steering_engine.dart' as steering;
import 'steering_game.dart';

void main() => runApp(WidgetsApp(
    color: const Color(0xff101a29),
    builder: (context, child) => const FlameExample()));

class FlameExample extends StatefulWidget {
  const FlameExample({super.key});
  @override
  State<FlameExample> createState() => _FlameExampleState();
}

class _FlameExampleState extends State<FlameExample> {
  final _game = SteeringDemoGame();
  @override
  Widget build(BuildContext context) => ColoredBox(
      color: const Color(0xff101a29),
      child: SafeArea(
          child: Column(children: [
        const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Steering Engine + Flame · Tap to move the target',
                style: TextStyle(color: Color(0xffd9e4f3), fontSize: 18))),
        Expanded(
            child: Center(
                child: AspectRatio(
                    aspectRatio: 1000 / 620,
                    child: LayoutBuilder(
                        builder: (context, constraints) => GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (event) {
                              _game.target = steering.Vec2(
                                  event.localPosition.dx /
                                      constraints.maxWidth *
                                      1000,
                                  event.localPosition.dy /
                                      constraints.maxHeight *
                                      620);
                            },
                            child: GameWidget(game: _game)))))),
        Padding(
            padding: const EdgeInsets.all(20),
            child: GestureDetector(
                onTap: _game.reset,
                child: const Text('Reset',
                    style: TextStyle(color: Color(0xff6ae4d4), fontSize: 18)))),
      ])));
  @override
  void dispose() {
    _game.dispose();
    super.dispose();
  }
}
