import 'package:steering_lab_ui/steering_lab_ui.dart';
import 'dart:math' as math;
// Preserve the lab's documented minimum Flutter SDK.
// ignore: deprecated_member_use
import 'package:flutter/material.dart' hide Alignment;
import 'package:steering_engine/steering_engine.dart';
import 'lab_theme.dart';
import 'lab_modes.dart';
import 'package:flutter/scheduler.dart';
import 'steering_painter.dart';

class LabPage extends StatefulWidget {
  const LabPage({super.key, this.initialMode = 'Arrive'});

  final String initialMode;

  @override
  State<LabPage> createState() => LabPageState();
}

class LabPageState extends State<LabPage> with SingleTickerProviderStateMixin {
  static const modes = labModes;
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
  double _separationWeight = 1.5;
  double _alignmentWeight = 1;
  double _cohesionWeight = 0.7;
  double _targetWeight = 0.2;
  int _population = 24;
  bool _useSpatial = true;
  double _physicsMs = 0;
  int _neighborCount = 0;
  final List<WallSegment> _walls = [
    WallSegment(Vec2(100, 150), Vec2(850, 150)),
    WallSegment(Vec2(850, 150), Vec2(850, 500)),
    WallSegment(Vec2(850, 500), Vec2(100, 500)),
    WallSegment(Vec2(100, 500), Vec2(100, 150)),
  ];
  WallFollowing get _wallRule =>
      WallFollowing(_walls, wallOffset: 20, lookAhead: 30, maxDistance: 150);
  List<SteeringAgent> _flock = const [];
  bool get _isGroupMode => const [
    'Separation',
    'Alignment',
    'Cohesion',
    'Flocking',
    'Queue',
  ].contains(_mode);
  final List<CircleObstacle> _obstacles = [
    CircleObstacle(Vec2(480, 300), radius: 60),
    CircleObstacle(Vec2(700, 450), radius: 45),
    CircleObstacle(Vec2(720, 100), radius: 40),
  ];

  ObstacleAvoidance get _avoidance => ObstacleAvoidance(
    _obstacles,
    agentRadius: 18,
    safetyMargin: _clearance,
    minLookAhead: 90,
    lookAheadTime: _lookAhead,
  );
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
  late FollowPolyline _polylineFollower;
  late final PolylinePath _polyline = PolylinePath(_route);

  @override
  void initState() {
    super.initState();
    _mode = modes.contains(widget.initialMode) ? widget.initialMode : 'Arrive';
    _reset();
    _ticker = createTicker(_tick)..start();
  }

  void selectMode(String mode) {
    if (!modes.contains(mode)) return;
    setState(() {
      _mode = mode;
      _reset();
    });
  }

  void _reset() {
    _agent = SteeringAgent(
      position: Vec2(260, 340),
      velocity: Vec2(35, 0),
      maxSpeed: _speed,
      maxAcceleration: _acceleration,
    );
    if (_isGroupMode) {
      final random = math.Random(42);
      _flock = List.unmodifiable(
        List.generate(_mode == 'Queue' ? 8 : _population, (i) {
          final angle = random.nextDouble() * math.pi * 2;
          if (_mode == 'Queue') {
            return SteeringAgent(
              position: Vec2(680 - i * 70.0, 310),
              maxSpeed: _speed,
              maxAcceleration: _acceleration,
            );
          }
          if (_population > 24) {
            return SteeringAgent(
              position: Vec2(
                40 + random.nextDouble() * 920,
                40 + random.nextDouble() * 540,
              ),
              velocity: Vec2(math.cos(angle), math.sin(angle)) * (_speed * .45),
              maxSpeed: _speed,
              maxAcceleration: _acceleration,
            );
          }
          return SteeringAgent(
            position: Vec2(
              300 + (i % 6) * 40 + random.nextDouble() * 8,
              230 + (i ~/ 6) * 40 + random.nextDouble() * 8,
            ),
            velocity: Vec2(math.cos(angle), math.sin(angle)) * (_speed * 0.45),
            maxSpeed: _speed,
            maxAcceleration: _acceleration,
          );
        }),
      );
      _agent = _flock.first;
    } else {
      _flock = const [];
    }
    if (_mode == 'Wall following') {
      _agent = SteeringAgent(
        position: Vec2(250, 190),
        velocity: Vec2(50, 0).limited(_speed),
        maxSpeed: _speed,
        maxAcceleration: _acceleration,
      );
    }
    _physicsMs = 0;
    _neighborCount = 0;
    _wander = Wander(seed: 42);
    _follower = FollowPath(_route, waypointRadius: 24, slowingRadius: 100);
    _polylineFollower = FollowPolyline(
      _polyline,
      lookAheadDistance: 45,
      searchDistance: 110,
      cornerSlowingDistance: 90,
    );
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
    var steps = 0;
    while (_accumulator >= 1 / 60 && steps < 3) {
      steps++;
      _advance();
      _accumulator -= 1 / 60;
      changed = true;
    }
    if (_accumulator >= 1 / 60) _accumulator %= 1 / 60;
    if (changed && mounted) setState(() {});
  }

  SteeringBehavior _behavior() {
    final moving = SteeringAgent(
      position: Vec2(
        650 + 170 * math.cos(_time * 0.5),
        310 + 150 * math.sin(_time * 0.5),
      ),
      velocity: Vec2(-85 * math.sin(_time * 0.5), 75 * math.cos(_time * 0.5)),
      maxSpeed: 100,
    );
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
        return PrioritySteering([
          _avoidance,
          Arrive(_target, slowingRadius: _slowing),
        ]);
      case 'Leader following':
        return LeaderFollowing(moving, distance: 65, avoidanceRadius: 18);
      case 'Wall following':
        return _wallRule;
      case 'Path following':
        return _follower;
      case 'Continuous path':
        return _polylineFollower;
      case 'Brake':
        return Brake();
      case 'Weighted blend':
        return WeightedBlend([
          WeightedBehavior(
            Arrive(_target, slowingRadius: _slowing),
            weight: 0.8,
          ),
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

  SteeringAgent _wrapped(SteeringAgent agent) => agent.copyWith(
    position: Vec2(
      agent.position.x % worldSize.width,
      agent.position.y % worldSize.height,
    ),
  );

  void _advanceFlock() {
    final snapshot = _useSpatial
        ? AgentNeighborhood.spatial(_flock, cellSize: 80)
        : AgentNeighborhood(_flock);
    _neighborCount = snapshot
        .neighborsFor(_flock.first, radius: _mode == 'Separation' ? 32 : 110)
        .length;
    final SteeringBehavior rule = switch (_mode) {
      'Queue' => QueueFollowing(
        snapshot,
        movement: Arrive(Vec2(920, 310), slowingRadius: 100),
        spacing: 55,
        lookAhead: 140,
        laneRadius: 18,
      ),
      'Separation' => Separation(snapshot, radius: 32),
      'Alignment' => Alignment(snapshot, radius: 110),
      'Cohesion' => Cohesion(snapshot, radius: 110),
      _ => WeightedBlend([
        WeightedBehavior(
          Flocking(
            snapshot,
            separationRadius: 32,
            neighborRadius: 110,
            separationWeight: _separationWeight,
            alignmentWeight: _alignmentWeight,
            cohesionWeight: _cohesionWeight,
          ),
        ),
        WeightedBehavior(
          Arrive(_target, slowingRadius: 150),
          weight: _targetWeight,
        ),
      ]),
    };
    // Sample the whole frame before replacing any agent snapshot.
    final forces = [for (final agent in _flock) rule.calculate(agent, 1 / 60)];
    final next = [
      for (var i = 0; i < _flock.length; i++)
        _wrapped(engine.step(_flock[i], _SampledForce(forces[i]), 1 / 60)),
    ];
    _flock = List.unmodifiable(next);
    _agent = _flock.first;
    _force = forces.first;
  }

  void _advance() {
    final timer = Stopwatch()..start();
    final previous = _agent.position;
    if (_isGroupMode) {
      _advanceFlock();
    } else {
      final force = _behavior().calculate(_agent, 1 / 60);
      _force = force;
      _agent = _wrapped(engine.step(_agent, _SampledForce(force), 1 / 60));
    }
    _time += 1 / 60;
    if ((_agent.position - previous).length > worldSize.height / 2) {
      _trail.clear();
    }
    _trail.add(_agent.position);
    if (_trail.length > 420) _trail.removeAt(0);
    timer.stop();
    _physicsMs = timer.elapsedMicroseconds / 1000;
  }

  SteeringAgent get _leaderSnapshot => SteeringAgent(
    position: Vec2(
      650 + 170 * math.cos(_time * .5),
      310 + 150 * math.sin(_time * .5),
    ),
    velocity: Vec2(-85 * math.sin(_time * .5), 75 * math.cos(_time * .5)),
    maxSpeed: 100,
  );

  Vec2 get _visibleTarget => _mode == 'Leader following'
      ? LeaderFollowing(
          _leaderSnapshot,
          distance: 65,
          avoidanceRadius: 18,
        ).target
      : _mode == 'Wall following'
      ? (_wallRule.targetFor(_agent) ?? _target)
      : _mode == 'Queue'
      ? Vec2(920, 310)
      : (_mode == 'Pursuit' || _mode == 'Evade')
      ? Vec2(
          650 + 170 * math.cos(_time * 0.5),
          310 + 150 * math.sin(_time * 0.5),
        )
      : _mode == 'Continuous path'
      ? _polylineFollower.currentTarget
      : _mode == 'Path following'
      ? _follower.currentTarget
      : _target;

  void _setTarget(Offset local, Size size) => setState(() {
    _target = Vec2(
      (local.dx / size.width * worldSize.width).clamp(0, worldSize.width),
      (local.dy / size.height * worldSize.height).clamp(0, worldSize.height),
    );
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'KLEBER ANDRADE / DART ENGINES'),
                style: TextStyle(
                  color: labMuted,
                  letterSpacing: 2,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 24,
                runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(context, 'Steering laboratory'),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        tr(context, 'Small rules. Emergent motion.'),
                        style: TextStyle(color: labMuted),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => setState(() {
                          _running = !_running;
                        }),
                        icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                        label: Text(tr(context, _running ? 'Pause' : 'Play')),
                      ),
                      OutlinedButton(
                        onPressed: _running ? null : () => setState(_advance),
                        child: Text(tr(context, 'Step')),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => setState(_reset),
                        icon: const Icon(Icons.refresh),
                        label: Text(tr(context, 'Reset')),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final controls = _controls();
                  final scene = _scene();
                  if (constraints.maxWidth < 900) {
                    return Column(
                      children: [scene, const SizedBox(height: 16), controls],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: scene),
                      const SizedBox(width: 20),
                      SizedBox(width: 280, child: controls),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                tr(
                  context,
                  'PURE DART CORE  ·  FIXED STEP 1/60 s  ·  NO RUNTIME DEPENDENCIES',
                ),
                style: TextStyle(
                  color: labMuted,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _scene() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        decoration: BoxDecoration(
          color: const Color(0xff111b2a),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xff263249)),
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: worldSize.aspectRatio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onTapDown: (event) => _setTarget(event.localPosition, size),
                onPanUpdate: (event) => _setTarget(event.localPosition, size),
                child: Semantics(
                  label: tr(
                    context,
                    'Steering canvas. Tap or drag to move the target.',
                  ),
                  child: CustomPaint(
                    key: const Key('simulation'),
                    painter: SteeringPainter(
                      flock: _flock,
                      walls: _mode == 'Wall following' ? _walls : const [],
                      leader: _mode == 'Leader following'
                          ? _leaderSnapshot
                          : null,
                      queueLane: _mode == 'Queue',
                      neighborhoodRadius: _isGroupMode
                          ? (_mode == 'Separation' ? 32 : 110)
                          : null,
                      avoidance: _mode == 'Obstacle avoidance'
                          ? _avoidance
                          : null,
                      route:
                          const [
                            'Path following',
                            'Continuous path',
                          ].contains(_mode)
                          ? _route
                          : null,
                      projection: _mode == 'Continuous path'
                          ? _polylineFollower.lastProjection
                          : null,
                      agent: _agent,
                      target: _visibleTarget,
                      force: _force,
                      trail: List.of(_trail),
                      showVectors: _vectors,
                      showTrail: _trails,
                      slowingRadius: _mode == 'Arrive' ? _slowing : null,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 20,
        runSpacing: 8,
        children: [
          _metric(
            'SPEED',
            '${_agent.velocity.length.toStringAsFixed(1)} u/s',
            labCyan,
          ),
          _metric(
            'ACCELERATION',
            '${_force.length.toStringAsFixed(1)} u/s²',
            const Color(0xffa497ff),
          ),
          if (_isGroupMode) _metric('POPULATION', '${_flock.length}', labCyan),
          _metric('PHYSICS', '${_physicsMs.toStringAsFixed(2)} ms', labGold),
          if (_isGroupMode) _metric('NEIGHBORS', '$_neighborCount', labCyan),
          _metric('SIMULATION', '${_time.toStringAsFixed(2)} s', labGold),
        ],
      ),
      const SizedBox(height: 14),
      Text(
        _isGroupMode
            ? (LabLanguage.of(context)
                  ? '${_flock.length} agentes compartilham um snapshot por passo. O anel mostra a vizinhança selecionada. Flocking pode seguir o alvo dourado.\nAs bordas se conectam visualmente; as distâncias são euclidianas.'
                  : '${_flock.length} agents share one snapshot per tick. The ring shows the selected agent’s neighborhood. Flocking optionally follows the gold target.\nEdges wrap visually; neighbor distances remain Euclidean.')
            : tr(
                context,
                'Tap or drag to move the gold target. Pursuit / Evade use an orbiting target. Path following uses the numbered route.\nEdges wrap for this demo; the core has no world boundaries.',
              ),
        style: const TextStyle(color: labMuted, height: 1.6, fontSize: 12),
      ),
    ],
  );

  Widget _metric(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        tr(context, label),
        style: const TextStyle(
          color: labMuted,
          fontSize: 10,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ],
  );

  Widget _controls() => Material(
    color: const Color(0xff111b2a),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xff263249)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'BEHAVIOR'),
            style: TextStyle(color: labMuted, letterSpacing: 1.5, fontSize: 11),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _mode,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final mode in modes)
                DropdownMenuItem(value: mode, child: Text(tr(context, mode))),
            ],
            onChanged: (mode) => setState(() {
              _mode = mode!;
              _reset();
            }),
          ),
          const SizedBox(height: 16),
          Text(
            tr(context, _description),
            style: const TextStyle(color: labMuted, height: 1.6, fontSize: 13),
          ),
          const Divider(height: 32),
          _slider(
            'Maximum speed',
            _speed,
            40,
            300,
            (value) => setState(() {
              _speed = value;
              if (_isGroupMode) {
                _flock = List.unmodifiable(
                  _flock.map(
                    (a) => a.copyWith(
                      maxSpeed: value,
                      velocity: a.velocity.limited(value),
                    ),
                  ),
                );
                _agent = _flock.first;
              } else {
                _agent = _agent.copyWith(
                  maxSpeed: value,
                  velocity: _agent.velocity.limited(value),
                );
              }
            }),
          ),
          _slider(
            'Maximum acceleration',
            _acceleration,
            30,
            500,
            (value) => setState(() {
              _acceleration = value;
              if (_isGroupMode) {
                _flock = List.unmodifiable(
                  _flock.map((a) => a.copyWith(maxAcceleration: value)),
                );
                _agent = _flock.first;
              } else {
                _agent = _agent.copyWith(maxAcceleration: value);
              }
            }),
          ),
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
              }),
            ),
          if (_isGroupMode && _mode != 'Queue') ...[
            DropdownButtonFormField<int>(
              initialValue: _population,
              isExpanded: true,
              decoration: InputDecoration(labelText: tr(context, 'Population')),
              items: [
                for (final count in [24, 100, 500, 1000])
                  DropdownMenuItem(
                    value: count,
                    child: Text(tr(context, '$count')),
                  ),
              ],
              onChanged: (value) => setState(() {
                _population = value!;
                _reset();
              }),
            ),
            SwitchListTile(
              key: const Key('spatial-toggle'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                tr(context, 'Spatial neighbor index'),
                style: TextStyle(fontSize: 13),
              ),
              value: _useSpatial,
              onChanged: (value) => setState(() {
                _useSpatial = value;
              }),
            ),
          ],
          if (_mode == 'Flocking') ...[
            _slider(
              'Separation weight',
              _separationWeight,
              0,
              3,
              (value) => setState(() {
                _separationWeight = value;
              }),
            ),
            _slider(
              'Alignment weight',
              _alignmentWeight,
              0,
              3,
              (value) => setState(() {
                _alignmentWeight = value;
              }),
            ),
            _slider(
              'Cohesion weight',
              _cohesionWeight,
              0,
              3,
              (value) => setState(() {
                _cohesionWeight = value;
              }),
            ),
            _slider(
              'Target attraction',
              _targetWeight,
              0,
              1,
              (value) => setState(() {
                _targetWeight = value;
              }),
            ),
          ],
          if (_mode == 'Obstacle avoidance') ...[
            Text(
              '${LabLanguage.of(context) ? 'Antecipação' : 'Look-ahead'} ${_lookAhead.toStringAsFixed(2)} s',
              style: const TextStyle(fontSize: 12),
            ),
            Slider(
              value: _lookAhead,
              min: 0,
              max: 3,
              onChanged: (value) => setState(() {
                _lookAhead = value;
              }),
            ),
            _slider(
              'Safety margin',
              _clearance,
              0,
              40,
              (value) => setState(() {
                _clearance = value;
              }),
            ),
            Text(
              tr(
                context,
                'Agent radius: 18 u. Orange rings include size + margin.\nLocal steering, not collision resolution.',
              ),
              style: TextStyle(color: labMuted, fontSize: 11, height: 1.6),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              tr(context, 'Velocity / force vectors'),
              style: TextStyle(fontSize: 13),
            ),
            value: _vectors,
            onChanged: (value) => setState(() {
              _vectors = value;
            }),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              tr(context, 'Motion trail'),
              style: TextStyle(fontSize: 13),
            ),
            value: _trails,
            onChanged: (value) => setState(() {
              _trails = value;
            }),
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              context,
              'Cyan: velocity · Violet: acceleration\nGold: target · Wander seed: 42',
            ),
            style: TextStyle(color: labMuted, fontSize: 11, height: 1.6),
          ),
        ],
      ),
    ),
  );

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${tr(context, label)}  ${value < 5 ? value.toStringAsFixed(2) : value.round()}',
        style: const TextStyle(fontSize: 12),
      ),
      Slider(value: value, min: min, max: max, onChanged: onChanged),
    ],
  );

  String get _description => switch (_mode) {
    'Leader following' =>
      'Arrive at a trailing point behind the moving leader. Local leader clearance takes priority.',
    'Queue' =>
      'Eight agents brake behind the nearest forward lane occupant, then resume arrival. This is spatial queuing.',
    'Wall following' =>
      'Project ahead onto a local wall segment and seek a tangential offset target. Corners are local decisions.',
    'Separation' =>
      'Nearby agents repel with distance-weighted acceleration. Exact overlaps have no invented escape direction.',
    'Alignment' =>
      'Agents match the mean velocity of neighbors within 110 units.',
    'Cohesion' =>
      'Agents accelerate toward the mean neighbor position, without damping shared motion.',
    'Flocking' =>
      'Combine separation, alignment and cohesion. Target attraction is a separate demo behavior and can be set to zero.',
    'Obstacle avoidance' =>
      'Avoid the first predicted circle, then resume arrival. Move the target to explore; points inside obstacles may be unreachable.',
    'Path following' =>
      'Follow a looping route. The gold ring marks the active waypoint; slow down near each corner.',
    'Continuous path' =>
      'Project ahead onto route segments. The cyan point is the projection; the gold target advances by arc distance with corner-speed preview.',
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
