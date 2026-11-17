import 'package:flutter_test/flutter_test.dart';
import 'package:steering_flame_example/steering_game.dart';
import 'package:steering_engine/steering_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('fixed-step Flame adapter advances all shared snapshots', () {
    final game = SteeringDemoGame();
    final before = game.agents.map((a) => a.position).toList();
    game.advance(1 / 60);
    expect(game.agents.length, before.length);
    for (var i = 0; i < before.length; i++) {
      expect(game.agents[i].position, isNot(before[i]));
    }
    expect(() => game.advance(-1), throwsArgumentError);
    game.reset();
    expect(game.agents.map((a) => a.position).toList(), before);
  });
  test('component transform is copied from the core state', () {
    final agent =
        SteeringAgent(position: Vec2(123, 456), velocity: Vec2(0, 10));
    final component = AgentView()..sync(agent);
    expect(component.position.x, 123);
    expect(component.position.y, 456);
    expect(component.angle, closeTo(1.5707963267948966, 1e-9));
  });
}
