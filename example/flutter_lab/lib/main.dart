import 'dart:math' as math;

// Preserve Flutter 3.35 compatibility while newer SDKs re-export Material here.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:steering_engine/steering_engine.dart';

void main() => runApp(const SteeringLab());

const _cyan = Color(0xff6ae4d4);
const _gold = Color(0xfff3c577);
const _muted = Color(0xff8b9bb4);
const _world = Size(1000, 620);

class SteeringLab extends StatelessWidget {
  const SteeringLab({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Steering Engine · Lab',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xff0b111c),
          colorScheme: ColorScheme.fromSeed(
              seedColor: _cyan, brightness: Brightness.dark),
          useMaterial3: true,
        ),
        home: const LabPage(),
      );
}

class LabPage extends StatefulWidget {
  const LabPage({super.key});

  @override
  State<LabPage> createState() => _LabPageState();
}

class _LabPageState extends State<LabPage> with SingleTickerProviderStateMixin {
  static const modes = [
    'Arrive',
    'Seek',
    'Flee',
    'Pursuit',
    'Evade',
    'Wander',
    'Brake',
    'Path following',
    'Obstacle avoidance',
    'Weighted blend',
    'Priority'
  ];
  static const engine = SteeringEngine();
  late final Ticker _ticker;
  Duration? _last;
  double _accumulator = 0;
  double _time = 0;
  String _mode = 'Arrive';
  bool _running = true;
  bool _vectors = true;
  bool _trails = true;
  double _speed = 140;
  double _acceleration = 220;
  double _slowing = 150;
  double _lookAhead = 1.2;
  double _clearance = 10;
  final List<CircleObstacle> _obstacles = [
    CircleObstacle(Vec2(480, 300), radius: 60),
    CircleObstacle(Vec2(700, 450), radius: 45),
    CircleObstacle(Vec2(720, 100), radius: 40),
  ];

  ObstacleAvoidance get _avoidance => ObstacleAvoidance(_obstacles,
      agentRadius: 18,
      safetyMargin: _clearance,
      minLookAhead: 90,
      lookAheadTime: _lookAhead);
  late SteeringAgent _agent;
  Wander _wander = Wander(seed: 42);
  Vec2 _target = Vec2(730, 280);
  Vec2 _force = Vec2.zero;
  final List<Vec2> _trail = [];
  final SteeringPath _route = SteeringPath([
    Vec2(260, 340),
    Vec2(350, 150),
    Vec2(750, 150),
    Vec2(820, 440),
    Vec2(350, 470),
  ], loop: true);
  late FollowPath _follower;

  @override
  void initState() {
    super.initState();
    _reset();
    _ticker = createTicker(_tick)..start();
  }

  void _reset() {
    _agent = SteeringAgent(
        position: Vec2(260, 340),
        velocity: Vec2(35, 0),
        maxSpeed: _speed,
        maxAcceleration: _acceleration);
    _wander = Wander(seed: 42);
    _follower = FollowPath(_route, waypointRadius: 24, slowingRadius: 100);
    _time = 0;
    _accumulator = 0;
    _last = null;
    _force = Vec2.zero;
    _trail.clear();
  }

  void _tick(Duration elapsed) {
    final previous = _last;
    _last = elapsed;
    if (!_running || previous == null) return;
    _accumulator += math.min(0.1, (elapsed - previous).inMicroseconds / 1e6);
    var changed = false;
    while (_accumulator >= 1 / 60) {
      _advance();
      _accumulator -= 1 / 60;
      changed = true;
    }
    if (changed && mounted) setState(() {});
  }

  SteeringBehavior _behavior() {
    final moving = SteeringAgent(
        position: Vec2(650 + 170 * math.cos(_time * 0.5),
            310 + 150 * math.sin(_time * 0.5)),
        velocity: Vec2(-85 * math.sin(_time * 0.5), 75 * math.cos(_time * 0.5)),
        maxSpeed: 100);
    switch (_mode) {
      case 'Seek':
        return Seek(_target);
      case 'Flee':
        return Flee(_target);
      case 'Pursuit':
        return Pursuit(moving);
      case 'Evade':
        return Evade(moving);
      case 'Wander':
        return _wander;
      case 'Obstacle avoidance':
        return PrioritySteering(
            [_avoidance, Arrive(_target, slowingRadius: _slowing)]);
      case 'Path following':
        return _follower;
      case 'Brake':
        return Brake();
      case 'Weighted blend':
        return WeightedBlend([
          WeightedBehavior(Arrive(_target, slowingRadius: _slowing),
              weight: 0.8),
          WeightedBehavior(_wander, weight: 0.2),
        ]);
      case 'Priority':
        return PrioritySteering([
          Arrive(_target, slowingRadius: _slowing),
          _wander,
        ], epsilon: 1);
      default:
        return Arrive(_target, slowingRadius: _slowing);
    }
  }

  void _advance() {
    final behavior = _behavior();
    // Evaluate exactly once: Wander owns a random stream.
    final force = behavior.calculate(_agent, 1 / 60);
    _force = force;
    _agent = engine.step(_agent, _SampledForce(force), 1 / 60);
    _time += 1 / 60;
    final p = _agent.position;
    if (p.x < 0 || p.x > _world.width || p.y < 0 || p.y > _world.height) {
      _agent = _agent.copyWith(
          position: Vec2(p.x % _world.width, p.y % _world.height));
      _trail.clear();
    }
    _trail.add(_agent.position);
    if (_trail.length > 420) _trail.removeAt(0);
  }

  Vec2 get _visibleTarget => (_mode == 'Pursuit' || _mode == 'Evade')
      ? Vec2(
          650 + 170 * math.cos(_time * 0.5), 310 + 150 * math.sin(_time * 0.5))
      : _mode == 'Path following'
          ? _follower.currentTarget
          : _target;

  void _setTarget(Offset local, Size size) => setState(() {
        _target = Vec2(
            (local.dx / size.width * _world.width).clamp(0, _world.width),
            (local.dy / size.height * _world.height).clamp(0, _world.height));
      });

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            child: SingleChildScrollView(
                child: Padding(
          padding: const EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('KLEBER ANDRADE / DART ENGINES',
                style:
                    TextStyle(color: _muted, letterSpacing: 2, fontSize: 11)),
            const SizedBox(height: 12),
            Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 24,
                runSpacing: 12,
                children: [
                  const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Steering laboratory',
                            style: TextStyle(
                                fontSize: 32, fontWeight: FontWeight.w700)),
                        Text('Small rules. Emergent motion.',
                            style: TextStyle(color: _muted)),
                      ]),
                  Wrap(spacing: 8, children: [
                    FilledButton.icon(
                        onPressed: () => setState(() {
                              _running = !_running;
                            }),
                        icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                        label: Text(_running ? 'Pause' : 'Play')),
                    OutlinedButton(
                        onPressed: _running ? null : () => setState(_advance),
                        child: const Text('Step')),
                    OutlinedButton.icon(
                        onPressed: () => setState(_reset),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset')),
                  ]),
                ]),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, constraints) {
              final controls = _controls();
              final scene = _scene();
              if (constraints.maxWidth < 900) {
                return Column(
                    children: [scene, const SizedBox(height: 16), controls]);
              }
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: scene),
                    const SizedBox(width: 20),
                    SizedBox(width: 280, child: controls),
                  ]);
            }),
            const SizedBox(height: 20),
            const Text(
                'PURE DART CORE  ·  FIXED STEP 1/60 s  ·  NO RUNTIME DEPENDENCIES',
                style:
                    TextStyle(color: _muted, fontSize: 11, letterSpacing: 1)),
          ]),
        ))),
      );

  Widget _scene() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            decoration: BoxDecoration(
                color: const Color(0xff111b2a),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xff263249))),
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
                aspectRatio: _world.aspectRatio,
                child: LayoutBuilder(builder: (context, constraints) {
                  final size =
                      Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    onTapDown: (event) => _setTarget(event.localPosition, size),
                    onPanUpdate: (event) =>
                        _setTarget(event.localPosition, size),
                    child: Semantics(
                        label:
                            'Steering canvas. Tap or drag to move the target.',
                        child: CustomPaint(
                            key: const Key('simulation'),
                            painter: SteeringPainter(
                                avoidance: _mode == 'Obstacle avoidance'
                                    ? _avoidance
                                    : null,
                                route:
                                    _mode == 'Path following' ? _route : null,
                                agent: _agent,
                                target: _visibleTarget,
                                force: _force,
                                trail: List.of(_trail),
                                showVectors: _vectors,
                                showTrail: _trails,
                                slowingRadius:
                                    _mode == 'Arrive' ? _slowing : null),
                            child: const SizedBox.expand())),
                  );
                }))),
        const SizedBox(height: 12),
        Wrap(spacing: 20, runSpacing: 8, children: [
          _metric('SPEED', '${_agent.velocity.length.toStringAsFixed(1)} u/s',
              _cyan),
          _metric('ACCELERATION', '${_force.length.toStringAsFixed(1)} u/s²',
              const Color(0xffa497ff)),
          _metric('SIMULATION', '${_time.toStringAsFixed(2)} s', _gold),
        ]),
        const SizedBox(height: 14),
        const Text(
            'Tap or drag to move the gold target. Pursuit / Evade use an orbiting target. Path following uses the numbered route.\nEdges wrap for this demo; the core has no world boundaries.',
            style: TextStyle(color: _muted, height: 1.6, fontSize: 12)),
      ]);

  Widget _metric(String label, String value, Color color) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: _muted, fontSize: 10, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 18,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ]);

  Widget _controls() => Material(
      color: const Color(0xff111b2a),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xff263249))),
      child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('BEHAVIOR',
                style:
                    TextStyle(color: _muted, letterSpacing: 1.5, fontSize: 11)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _mode,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), isDense: true),
                items: [
                  for (final mode in modes)
                    DropdownMenuItem(value: mode, child: Text(mode))
                ],
                onChanged: (mode) => setState(() {
                      _mode = mode!;
                      _reset();
                    })),
            const SizedBox(height: 16),
            Text(_description,
                style:
                    const TextStyle(color: _muted, height: 1.6, fontSize: 13)),
            const Divider(height: 32),
            _slider(
                'Maximum speed',
                _speed,
                40,
                300,
                (value) => setState(() {
                      _speed = value;
                      _agent = _agent.copyWith(
                          maxSpeed: value,
                          velocity: _agent.velocity.limited(value));
                    })),
            _slider(
                'Maximum acceleration',
                _acceleration,
                30,
                500,
                (value) => setState(() {
                      _acceleration = value;
                      _agent = _agent.copyWith(maxAcceleration: value);
                    })),
            if (_mode == 'Arrive' ||
                _mode == 'Weighted blend' ||
                _mode == 'Priority' ||
                _mode == 'Obstacle avoidance')
              _slider(
                  'Slowing radius',
                  _slowing,
                  40,
                  250,
                  (value) => setState(() {
                        _slowing = value;
                      })),
            if (_mode == 'Obstacle avoidance') ...[
              Text('Look-ahead ${_lookAhead.toStringAsFixed(2)} s',
                  style: const TextStyle(fontSize: 12)),
              Slider(
                  value: _lookAhead,
                  min: 0,
                  max: 3,
                  onChanged: (value) => setState(() {
                        _lookAhead = value;
                      })),
              _slider(
                  'Safety margin',
                  _clearance,
                  0,
                  40,
                  (value) => setState(() {
                        _clearance = value;
                      })),
              const Text(
                  'Agent radius: 18 u. Orange rings include size + margin.\nLocal steering, not collision resolution.',
                  style: TextStyle(color: _muted, fontSize: 11, height: 1.6)),
            ],
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Velocity / force vectors',
                    style: TextStyle(fontSize: 13)),
                value: _vectors,
                onChanged: (value) => setState(() {
                      _vectors = value;
                    })),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title:
                    const Text('Motion trail', style: TextStyle(fontSize: 13)),
                value: _trails,
                onChanged: (value) => setState(() {
                      _trails = value;
                    })),
            const SizedBox(height: 8),
            const Text(
                'Cyan: velocity · Violet: acceleration\nGold: target · Wander seed: 42',
                style: TextStyle(color: _muted, fontSize: 11, height: 1.6)),
          ])));

  Widget _slider(String label, double value, double min, double max,
          ValueChanged<double> onChanged) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$label  ${value.round()}', style: const TextStyle(fontSize: 12)),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ]);

  String get _description => switch (_mode) {
        'Obstacle avoidance' =>
          'Avoid the first predicted circle, then resume arrival. Move the target to explore; points inside obstacles may be unreachable.',
        'Path following' =>
          'Follow a looping route. The gold ring marks the active waypoint; slow down near each corner.',
        'Seek' =>
          'Accelerate toward the target. Momentum carries the agent past it.',
        'Flee' =>
          'Accelerate away from the target while respecting the same motion limits.',
        'Pursuit' =>
          'Predict a moving target up to one second ahead, then seek that position.',
        'Evade' =>
          'Predict the moving threat, then steer away from its future position.',
        'Wander' =>
          'A seeded random stream changes a local target ahead of the agent.',
        'Brake' => 'Approach zero velocity with bounded deceleration.',
        'Weighted blend' =>
          'Combine 80% Arrive with 20% Wander, then cap total acceleration.',
        'Priority' =>
          'Use Arrive when its acceleration exceeds 1 u/s²; otherwise evaluate Wander.',
        _ =>
          'Reduce desired speed inside the slowing radius and brake near the target.',
      };
}

class _SampledForce implements SteeringBehavior {
  _SampledForce(this.force);
  final Vec2 force;
  @override
  Vec2 calculate(SteeringAgent agent, double dt) => force;
}

class SteeringPainter extends CustomPainter {
  SteeringPainter(
      {required this.agent,
      required this.target,
      required this.force,
      required this.trail,
      required this.showVectors,
      required this.showTrail,
      this.route,
      this.avoidance,
      this.slowingRadius});
  final SteeringPath? route;
  final ObstacleAvoidance? avoidance;
  final SteeringAgent agent;
  final Vec2 target;
  final Vec2 force;
  final List<Vec2> trail;
  final bool showVectors;
  final bool showTrail;
  final double? slowingRadius;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _world.width, size.height / _world.height);
    final grid = Paint()
      ..color = const Color(0xff1e2c40)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= _world.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, _world.height), grid);
    }
    for (var y = 0.0; y <= _world.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(_world.width, y), grid);
    }
    Offset offset(Vec2 v) => Offset(v.x, v.y);
    if (avoidance != null) {
      final behavior = avoidance!;
      final threat = behavior.findThreat(agent);
      for (final obstacle in behavior.obstacles) {
        final selected = identical(obstacle, threat?.obstacle);
        canvas.drawCircle(offset(obstacle.center), obstacle.radius,
            Paint()..color = Color(selected ? 0xffc66855 : 0xff66494c));
        canvas.drawCircle(
            offset(obstacle.center),
            obstacle.radius + behavior.agentRadius + behavior.safetyMargin,
            Paint()
              ..color = const Color(0xffe7a36a)
                  .withValues(alpha: selected ? 0.9 : 0.35)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      }
      canvas.drawCircle(
          offset(agent.position),
          behavior.agentRadius,
          Paint()
            ..color = _cyan.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke);
      if (agent.velocity.length > 0) {
        final end = agent.position +
            agent.velocity.normalized * behavior.scanDistance(agent);
        canvas.drawLine(
            offset(agent.position),
            offset(end),
            Paint()
              ..color = const Color(0xffe7a36a)
              ..strokeWidth = 1.5);
        if (threat != null && !threat.isOverlapping) {
          final entry =
              agent.position + agent.velocity.normalized * threat.entryDistance;
          canvas.drawCircle(
              offset(entry), 5, Paint()..color = const Color(0xffffd298));
        }
      }
    }
    if (route != null) {
      final points = route!.waypoints;
      final path = Path()..moveTo(points.first.x, points.first.y);
      for (final point in points.skip(1)) {
        path.lineTo(point.x, point.y);
      }
      if (route!.loop) path.close();
      canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xffa497ff).withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      for (var i = 0; i < points.length; i++) {
        canvas.drawCircle(
            offset(points[i]), 5, Paint()..color = const Color(0xffa497ff));
        final label = TextPainter(
            text: TextSpan(
                text: '${i + 1}',
                style: const TextStyle(color: Color(0xffa497ff), fontSize: 14)),
            textDirection: TextDirection.ltr)
          ..layout();
        label.paint(canvas, offset(points[i]) + const Offset(9, -18));
      }
    }
    if (showTrail && trail.length > 1) {
      final path = Path()..moveTo(trail.first.x, trail.first.y);
      for (final point in trail.skip(1)) {
        path.lineTo(point.x, point.y);
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = _cyan.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    if (slowingRadius != null) {
      canvas.drawCircle(offset(target), slowingRadius!,
          Paint()..color = _gold.withValues(alpha: 0.05));
      canvas.drawCircle(
          offset(target),
          slowingRadius!,
          Paint()
            ..color = _gold.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
    canvas.drawCircle(
        offset(target),
        13,
        Paint()
          ..color = _gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawCircle(offset(target), 4, Paint()..color = _gold);
    final origin = offset(agent.position);
    if (showVectors) {
      _arrow(canvas, origin, offset(agent.position + agent.velocity * 0.65),
          _cyan);
      _arrow(canvas, origin, offset(agent.position + force * 0.35),
          const Color(0xffa497ff));
    }
    final heading = math.atan2(agent.velocity.y, agent.velocity.x);
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(heading);
    canvas.drawCircle(
        Offset.zero, 24, Paint()..color = _cyan.withValues(alpha: 0.08));
    final body = Path()
      ..moveTo(18, 0)
      ..lineTo(-12, -10)
      ..lineTo(-7, 0)
      ..lineTo(-12, 10)
      ..close();
    canvas.drawPath(body, Paint()..color = _cyan);
    canvas.restore();
    canvas.restore();
  }

  void _arrow(Canvas canvas, Offset from, Offset to, Color color) {
    if ((to - from).distance < 1) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5;
    canvas.drawLine(from, to, paint);
    final a = math.atan2(to.dy - from.dy, to.dx - from.dx);
    for (final side in [-1, 1]) {
      canvas.drawLine(
          to,
          to - Offset(math.cos(a + side * 0.5), math.sin(a + side * 0.5)) * 9,
          paint);
    }
  }

  @override
  bool shouldRepaint(SteeringPainter oldDelegate) => true;
}
