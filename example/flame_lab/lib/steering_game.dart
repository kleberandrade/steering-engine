import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:steering_engine/steering_engine.dart' as steering;

class SteeringDemoGame extends FlameGame {
  SteeringDemoGame()
      : super(
            camera:
                CameraComponent.withFixedResolution(width: 1000, height: 620)) {
    reset();
  }
  List<steering.SteeringAgent> _agents = [];
  final List<AgentView> _views = [];
  List<steering.SteeringAgent> get agents => _agents;
  steering.Vec2 target = steering.Vec2(750, 300);
  double _accumulator = 0;
  CircleComponent? _targetView;
  void reset() {
    _accumulator = 0;
    _agents = List.unmodifiable(List.generate(
        24,
        (i) => steering.SteeringAgent(
            position:
                steering.Vec2(100 + (i % 6) * 35.0, 180 + (i ~/ 6) * 35.0),
            velocity: steering.Vec2(40, 0),
            maxSpeed: 120,
            maxAcceleration: 200)));
    _syncViews();
  }

  @override
  Color backgroundColor() => const Color(0xff101a29);
  @override
  Future<void> onLoad() async {
    camera.viewfinder.position = Vector2(500, 310);
    _views.addAll([for (final _ in _agents) AgentView()]);
    await world.addAll(_views);
    _targetView = CircleComponent(
        radius: 6,
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xfff3c577));
    await world.add(_targetView!);
    _syncViews();
  }

  void _syncViews() {
    for (var i = 0; i < _views.length; i++) {
      _views[i].sync(_agents[i]);
    }
    _targetView?.position.setValues(target.x, target.y);
  }

  void advance(double dt) {
    if (!dt.isFinite || dt < 0) throw ArgumentError.value(dt, 'dt');
    _accumulator += math.min(dt, .1);
    var steps = 0;
    while (_accumulator >= 1 / 60 && steps < 3) {
      final observed = steering.AgentNeighborhood.spatial(_agents);
      final rule = steering.WeightedBlend([
        steering.WeightedBehavior(steering.Flocking(observed)),
        steering.WeightedBehavior(steering.Arrive(target, slowingRadius: 120),
            weight: .2),
      ]);
      _agents = List.unmodifiable([
        for (final agent in _agents)
          const steering.SteeringEngine().step(agent, rule, 1 / 60)
      ]);
      _accumulator -= 1 / 60;
      steps++;
    }
    if (_accumulator >= 1 / 60) _accumulator %= 1 / 60;
    _syncViews();
  }

  @override
  void update(double dt) {
    super.update(dt);
    advance(dt);
  }
}

class AgentView extends PositionComponent {
  AgentView() : super(size: Vector2.all(20), anchor: Anchor.center);
  void sync(steering.SteeringAgent agent) {
    position.setValues(agent.position.x, agent.position.y);
    angle = math.atan2(agent.velocity.y, agent.velocity.x);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawPath(
        Path()
          ..moveTo(20, 10)
          ..lineTo(0, 0)
          ..lineTo(4, 10)
          ..lineTo(0, 20)
          ..close(),
        Paint()..color = const Color(0xff6ae4d4));
  }
}
