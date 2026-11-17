import 'dart:math' as math;
// Preserve the lab's documented minimum Flutter SDK.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:steering_engine/steering_engine.dart';
import 'lab_theme.dart';
import 'package:flutter/scheduler.dart';
import 'steering_painter.dart';

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
    if (p.x < 0 || p.x > worldSize.width || p.y < 0 || p.y > worldSize.height) {
      _agent = _agent.copyWith(
          position: Vec2(p.x % worldSize.width, p.y % worldSize.height));
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
            (local.dx / size.width * worldSize.width).clamp(0, worldSize.width),
            (local.dy / size.height * worldSize.height)
                .clamp(0, worldSize.height));
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
                    TextStyle(color: labMuted, letterSpacing: 2, fontSize: 11)),
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
                            style: TextStyle(color: labMuted)),
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
                    TextStyle(color: labMuted, fontSize: 11, letterSpacing: 1)),
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
                aspectRatio: worldSize.aspectRatio,
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
              labCyan),
          _metric('ACCELERATION', '${_force.length.toStringAsFixed(1)} u/s²',
              const Color(0xffa497ff)),
          _metric('SIMULATION', '${_time.toStringAsFixed(2)} s', labGold),
        ]),
        const SizedBox(height: 14),
        const Text(
            'Tap or drag to move the gold target. Pursuit / Evade use an orbiting target. Path following uses the numbered route.\nEdges wrap for this demo; the core has no world boundaries.',
            style: TextStyle(color: labMuted, height: 1.6, fontSize: 12)),
      ]);

  Widget _metric(String label, String value, Color color) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: labMuted, fontSize: 10, letterSpacing: 1.2)),
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
                style: TextStyle(
                    color: labMuted, letterSpacing: 1.5, fontSize: 11)),
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
                style: const TextStyle(
                    color: labMuted, height: 1.6, fontSize: 13)),
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
                  style: TextStyle(color: labMuted, fontSize: 11, height: 1.6)),
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
                style: TextStyle(color: labMuted, fontSize: 11, height: 1.6)),
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
