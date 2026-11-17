// Keep compatibility with Flutter versions that do not re-export Material.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'platform_stub.dart'
    if (dart.library.js_interop) 'platform_web.dart'
    as platform;

class LabLanguage extends InheritedWidget {
  const LabLanguage({
    super.key,
    required this.portuguese,
    required super.child,
  });
  final bool portuguese;
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LabLanguage>()?.portuguese ??
      false;
  @override
  bool updateShouldNotify(LabLanguage oldWidget) =>
      portuguese != oldWidget.portuguese;
}

String tr(BuildContext context, String value) =>
    LabLanguage.of(context) ? (translations[value] ?? value) : value;

/// Original "orbit and heading" mark: an open orbit crossed by a moving agent.
class SteeringMark extends StatelessWidget {
  const SteeringMark({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Steering Engine',
    image: true,
    child: SizedBox(
      width: 38,
      height: 38,
      child: CustomPaint(painter: _MarkPainter()),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 40, size.height / 40);
    canvas.drawArc(
      const Rect.fromLTWH(3, 3, 34, 34),
      .5,
      4.8,
      false,
      Paint()
        ..color = const Color(0xff6ae4d4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawPath(
      Path()
        ..moveTo(13, 26)
        ..lineTo(29, 10)
        ..lineTo(25, 29)
        ..lineTo(21, 21)
        ..close(),
      Paint()..color = const Color(0xffffce77),
    );
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}

class LabShell extends StatefulWidget {
  const LabShell({
    super.key,
    required this.laboratory,
    this.onPreset,
    this.flame = false,
  });
  final Widget laboratory;
  final ValueChanged<String>? onPreset;
  final bool flame;
  @override
  State<LabShell> createState() => _LabShellState();
}

class _LabShellState extends State<LabShell> {
  int _page = 0;
  late bool _pt = platform.loadLanguage() == 'pt';
  String text(String en, String pt) => _pt ? pt : en;
  void preset(String mode) {
    widget.onPreset?.call(mode);
    setState(() => _page = 0);
  }

  @override
  Widget build(BuildContext context) => Localizations.override(
    context: context,
    locale: Locale(_pt ? 'pt' : 'en'),
    delegates: const [
      // Preserve compatibility with the lab’s minimum Flutter SDK.
      // ignore: deprecated_member_use
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      // ignore: deprecated_member_use
      GlobalCupertinoLocalizations.delegate,
    ],
    child: LabLanguage(
      portuguese: _pt,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 76,
          title: const Row(
            children: [
              SteeringMark(),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Steering Engine',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<bool>(
              key: const Key('language'),
              tooltip: text('Language', 'Idioma'),
              initialValue: _pt,
              onSelected: (value) {
                setState(() => _pt = value);
                platform.saveLanguage(value ? 'pt' : 'en');
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: false, child: Text('English')),
                PopupMenuItem(value: true, child: Text('Português')),
              ],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.language),
                    const SizedBox(width: 4),
                    Text(_pt ? 'PT-BR' : 'EN'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    for (final (index, label, icon) in [
                      (
                        0,
                        text('Laboratory', 'Laboratório'),
                        Icons.science_outlined,
                      ),
                      (1, text('Learn', 'Aprender'), Icons.school_outlined),
                      (
                        2,
                        text('Examples', 'Exemplos'),
                        Icons.play_circle_outline,
                      ),
                      (
                        3,
                        text('Documentation', 'Documentação'),
                        Icons.menu_book_outlined,
                      ),
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: TextButton.icon(
                          onPressed: () => setState(() => _page = index),
                          style: TextButton.styleFrom(
                            foregroundColor: _page == index
                                ? const Color(0xff6ae4d4)
                                : Colors.white70,
                            backgroundColor: _page == index
                                ? const Color(0xff193936)
                                : null,
                          ),
                          icon: Icon(icon, size: 18),
                          label: Text(label),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: IndexedStack(
          index: _page,
          children: [
            TickerMode(enabled: _page == 0, child: widget.laboratory),
            _learning(),
            _examples(),
            _documentation(),
          ],
        ),
      ),
    ),
  );

  Widget _pageBody(List<Widget> children) => SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    ),
  );
  Widget _heading(String value) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 16),
    child: Text(
      value,
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
    ),
  );
  Widget _lesson(String title, String body, String equation) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(body, style: const TextStyle(height: 1.65)),
          const SizedBox(height: 14),
          SelectableText(
            equation,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Color(0xff6ae4d4),
            ),
          ),
        ],
      ),
    ),
  );
  Widget _learning() => _pageBody([
    _heading(
      text('Motion from small rules', 'Movimento a partir de pequenas regras'),
    ),
    Text(
      text(
        'Explore a behavior, predict its motion, then compare your prediction with the experiment. These lessons follow the project’s equations and conventions.',
        'Explore um comportamento, preveja o movimento e compare com o experimento. Estas lições seguem as equações e convenções do projeto.',
      ),
    ),
    _lesson(
      text('1 · Steering and integration', '1 · Direção e integração'),
      text(
        'Position p, velocity v and acceleration a have consistent world units. dt is measured in seconds. limit preserves direction while capping magnitude. The demo uses a fixed 1/60 s step and semi-implicit Euler.',
        'Posição p, velocidade v e aceleração a usam unidades de mundo consistentes. dt está em segundos. limit preserva a direção e limita a magnitude. A demonstração usa passo fixo de 1/60 s e Euler semi-implícito.',
      ),
      'vNext = limit(v + a × dt, maxSpeed)\npNext = p + vNext × dt',
    ),
    _lesson(
      text('2 · Seek versus Arrive', '2 · Seek e Arrive'),
      text(
        'Seek requests full speed toward the target, so momentum causes overshoot. Arrive reduces desired speed inside the slowing radius. Acceleration remains bounded: arrival does not teleport or guarantee an exact analytic stop.',
        'Seek solicita velocidade máxima rumo ao alvo e pode ultrapassá-lo por inércia. Arrive reduz a velocidade desejada dentro do raio de desaceleração. A aceleração é limitada: a chegada não teleporta nem garante uma parada analítica exata.',
      ),
      'desired = normalize(target − p) × desiredSpeed\na = limit((desired − v) / responseTime, maxAcceleration)',
    ),
    _lesson(
      text('3 · Collective behavior', '3 · Comportamento coletivo'),
      text(
        'Separation repels nearby agents, alignment matches neighbor velocity, and cohesion seeks their mean position. Evaluate neighbors from one shared snapshot. Weighted composition sums accelerations and caps the result; weights are not normalized.',
        'Separação repele vizinhos próximos, alinhamento aproxima velocidades e coesão busca a posição média. Calcule vizinhos a partir do mesmo snapshot. A composição ponderada soma acelerações e limita o resultado; os pesos não são normalizados.',
      ),
      'a = limit(Σ(weightᵢ × accelerationᵢ), maxAcceleration)',
    ),
    _lesson(
      text('4 · Limits of this simulation', '4 · Limites desta simulação'),
      text(
        'The full Flutter demo wraps world edges; the Flame example does not. Neighbor distances remain Euclidean. Steering is local navigation, without rigid-body collision response or global route planning. Seeded Wander owns state per agent.',
        'O laboratório Flutter conecta as bordas; o exemplo Flame não. As distâncias entre vizinhos são euclidianas. Steering é navegação local, sem resposta de colisão de corpos rígidos ou planejamento global. Wander usa estado e semente por agente.',
      ),
      'dt = 1 / 60 s',
    ),
    if (widget.flame) _fullLabLink(),
    _heading(
      text('Practice · five experiments', 'Prática · cinco experimentos'),
    ),
    for (final exercise
        in (_pt
            ? const [
                '1. Compare Seek e Arrive: registre se cada agente ultrapassa o alvo e explique a diferença.',
                '2. Pause e avance um passo: confirme que o tempo aumenta aproximadamente 1/60 s.',
                '3. Reduza a aceleração máxima: compare o tempo de mudança de direção com o cenário inicial.',
                '4. Em Flocking, zere a atração pelo alvo: observe o grupo por 10 s e descreva separação, alinhamento e coesão.',
                '5. Em desvio de obstáculos, mova o alvo para dentro de um círculo: identifique por que o destino pode ser inalcançável.',
              ]
            : const [
                '1. Compare Seek and Arrive: record whether each agent overshoots and explain the difference.',
                '2. Pause and single-step: verify that simulation time advances by approximately 1/60 s.',
                '3. Reduce maximum acceleration: compare turning time with the original scenario.',
                '4. In Flocking, set target attraction to zero: observe the group for 10 s and describe separation, alignment and cohesion.',
                '5. In obstacle avoidance, move the target inside a circle: identify why the destination may be unreachable.',
              ]))
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(exercise),
      ),
  ]);
  Widget _examples() => _pageBody([
    _heading(text('Try a guided experiment', 'Experimente um cenário guiado')),
    Text(
      text(
        'Selecting a preset intentionally resets the scene. Navigation and language changes preserve it.',
        'Selecionar um cenário reinicia a cena intencionalmente. Navegação e idioma preservam o estado.',
      ),
    ),
    if (widget.flame)
      _lesson(
        'Flame',
        text(
          'Tap the field to change the target. Twenty-four agents combine Flocking with 20% Arrive attraction; Reset restores their initial positions. Open the full laboratory for other behaviors.',
          'Toque no campo para mudar o alvo. Vinte e quatro agentes combinam Flocking com 20% de atração Arrive; Reiniciar restaura as posições iniciais. Abra o laboratório completo para outros comportamentos.',
        ),
        'SteeringComponent → SteeringEngine → immutable snapshot',
      ),
    if (!widget.flame)
      for (final (mode, en, pt) in [
        ('Seek', 'Overshoot and momentum', 'Inércia e ultrapassagem'),
        ('Arrive', 'Controlled arrival', 'Chegada controlada'),
        (
          'Flocking',
          'Emergent collective motion',
          'Movimento coletivo emergente',
        ),
        (
          'Obstacle avoidance',
          'Local obstacle avoidance',
          'Desvio local de obstáculos',
        ),
      ])
        Card(
          child: ListTile(
            title: Text(_pt ? translations[mode] ?? mode : mode),
            subtitle: Text(text(en, pt)),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => preset(mode),
          ),
        ),
  ]);
  Widget _fullLabLink() => TextButton.icon(
    icon: const Icon(Icons.open_in_new),
    label: Text(
      text(
        'Open the full laboratory for these exercises',
        'Abra o laboratório completo para estes exercícios',
      ),
    ),
    onPressed: () {
      const url = 'https://kleberandrade.github.io/steering-engine/';
      if (!platform.openDocumentation(url)) {
        showDialog<void>(
          context: context,
          builder: (context) => const AlertDialog(content: SelectableText(url)),
        );
      }
    },
  );
  Widget _documentation() => _pageBody([
    _heading(text('Documentation and source', 'Documentação e código')),
    Text(
      text(
        'The learning area summarizes these maintained sources. Open the full reference for all behaviors, edge cases and API details.',
        'A área educativa resume estas fontes mantidas no projeto. Abra a referência completa para todos os comportamentos, casos extremos e detalhes da API.',
      ),
    ),
    for (final (label, path) in [
      (text('Learning guide', 'Guia didático'), 'doc/wiki/Home.md'),
      (text('Equations', 'Equações'), 'doc/behaviors.md'),
      (text('Public API', 'API pública'), 'lib/steering_engine.dart'),
      ('GitHub', ''),
    ])
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          title: Text(label),
          subtitle: SelectableText(
            'https://github.com/kleberandrade/steering-engine/${path.isEmpty ? '' : 'blob/main/$path'}',
          ),
          trailing: IconButton(
            tooltip: text('Open documentation', 'Abrir documentação'),
            icon: const Icon(Icons.open_in_new),
            onPressed: () {
              final url =
                  'https://github.com/kleberandrade/steering-engine/${path.isEmpty ? '' : 'blob/main/$path'}';
              if (!platform.openDocumentation(url)) {
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      text('Documentation link', 'Link da documentação'),
                    ),
                    content: SelectableText(url),
                  ),
                );
              }
            },
          ),
        ),
      ),
  ]);
}

const translations = <String, String>{
  "Steering laboratory": "Laboratório de steering",
  "Small rules. Emergent motion.": "Pequenas regras. Movimento emergente.",
  "Pause": "Pausar",
  "Play": "Continuar",
  "Step": "Avançar",
  "Reset": "Reiniciar",
  "SPEED": "VELOCIDADE",
  "ACCELERATION": "ACELERAÇÃO",
  "POPULATION": "POPULAÇÃO",
  "PHYSICS": "FÍSICA",
  "NEIGHBORS": "VIZINHOS",
  "SIMULATION": "SIMULAÇÃO",
  "BEHAVIOR": "COMPORTAMENTO",
  "Maximum speed": "Velocidade máxima",
  "Maximum acceleration": "Aceleração máxima",
  "Slowing radius": "Raio de desaceleração",
  "Population": "População",
  "Spatial neighbor index": "Índice espacial de vizinhos",
  "Separation weight": "Peso de separação",
  "Alignment weight": "Peso de alinhamento",
  "Cohesion weight": "Peso de coesão",
  "Target attraction": "Atração pelo alvo",
  "Safety margin": "Margem de segurança",
  "Velocity / force vectors": "Vetores de velocidade e força",
  "Motion trail": "Rastro de movimento",
  "Steering canvas. Tap or drag to move the target.":
      "Simulação de steering. Toque ou arraste para mover o alvo.",
  "PURE DART CORE  ·  FIXED STEP 1/60 s  ·  NO RUNTIME DEPENDENCIES":
      "NÚCLEO DART PURO  ·  PASSO FIXO 1/60 s  ·  SEM DEPENDÊNCIAS DE EXECUÇÃO",
  "Cyan: velocity · Violet: acceleration\nGold: target · Wander seed: 42":
      "Ciano: velocidade · Violeta: aceleração\nDourado: alvo · Semente de Wander: 42",
  "Agent radius: 18 u. Orange rings include size + margin.\nLocal steering, not collision resolution.":
      "Raio do agente: 18 u. Anéis laranja incluem tamanho + margem.\nDireção local, sem resolução de colisões.",
  "Tap or drag to move the gold target. Pursuit / Evade use an orbiting target. Path following uses the numbered route.\nEdges wrap for this demo; the core has no world boundaries.":
      "Toque ou arraste para mover o alvo dourado. Pursuit / Evade usam um alvo orbital. O seguimento de caminho usa a rota numerada.\nAs bordas se conectam nesta demonstração; o núcleo não define limites do mundo.",
  "Seek": "Buscar (Seek)",
  "Flee": "Fugir (Flee)",
  "Arrive": "Chegar (Arrive)",
  "Pursuit": "Perseguir (Pursuit)",
  "Evade": "Escapar (Evade)",
  "Wander": "Vagar (Wander)",
  "Brake": "Frear (Brake)",
  "Weighted blend": "Composição ponderada",
  "Priority": "Prioridade",
  "Path following": "Seguir caminho",
  "Continuous path": "Caminho contínuo",
  "Obstacle avoidance": "Desvio de obstáculos",
  "Leader following": "Seguir líder",
  "Wall following": "Seguir parede",
  "Queue": "Fila",
  "Separation": "Separação",
  "Alignment": "Alinhamento",
  "Cohesion": "Coesão",
  "Flocking": "Movimento coletivo",
  "Arrive at a trailing point behind the moving leader. Local leader clearance takes priority.":
      "Chega a um ponto atrás do líder em movimento. Manter distância do líder tem prioridade.",
  "Eight agents brake behind the nearest forward lane occupant, then resume arrival. This is spatial queuing.":
      "Oito agentes freiam atrás do ocupante mais próximo à frente e retomam a chegada. Esta é uma fila espacial.",
  "Project ahead onto a local wall segment and seek a tangential offset target. Corners are local decisions.":
      "Projeta à frente em um segmento de parede e busca um alvo tangencial deslocado. As decisões de curva são locais.",
  "Nearby agents repel with distance-weighted acceleration. Exact overlaps have no invented escape direction.":
      "Agentes próximos se repelem com aceleração ponderada pela distância. Sobreposições exatas não inventam uma direção de fuga.",
  "Agents match the mean velocity of neighbors within 110 units.":
      "Os agentes aproximam a velocidade média dos vizinhos em até 110 unidades.",
  "Agents accelerate toward the mean neighbor position, without damping shared motion.":
      "Os agentes aceleram rumo à posição média dos vizinhos, sem amortecer o movimento compartilhado.",
  "Combine separation, alignment and cohesion. Target attraction is a separate demo behavior and can be set to zero.":
      "Combina separação, alinhamento e coesão. A atração pelo alvo é separada e pode ser zerada.",
  "Avoid the first predicted circle, then resume arrival. Move the target to explore; points inside obstacles may be unreachable.":
      "Desvia do primeiro círculo previsto e retoma a chegada. Mova o alvo; pontos dentro de obstáculos podem ser inalcançáveis.",
  "Follow a looping route. The gold ring marks the active waypoint; slow down near each corner.":
      "Segue uma rota cíclica. O anel dourado marca o ponto ativo; reduz a velocidade perto de cada curva.",
  "Project ahead onto route segments. The cyan point is the projection; the gold target advances by arc distance with corner-speed preview.":
      "Projeta à frente nos segmentos da rota. O ponto ciano é a projeção; o alvo dourado avança pela distância de arco prevendo curvas.",
  "Accelerate toward the target. Momentum carries the agent past it.":
      "Acelera rumo ao alvo. A inércia leva o agente além dele.",
  "Accelerate away from the target while respecting the same motion limits.":
      "Acelera para longe do alvo respeitando os mesmos limites de movimento.",
  "Predict a moving target up to one second ahead, then seek that position.":
      "Prevê o alvo móvel até um segundo à frente e busca essa posição.",
  "Predict the moving threat, then steer away from its future position.":
      "Prevê a ameaça móvel e se afasta da posição futura.",
  "A seeded random stream changes a local target ahead of the agent.":
      "Uma sequência aleatória com semente modifica um alvo local à frente do agente.",
  "Approach zero velocity with bounded deceleration.":
      "Aproxima a velocidade de zero com desaceleração limitada.",
  "Combine 80% Arrive with 20% Wander, then cap total acceleration.":
      "Combina 80% Arrive com 20% Wander e limita a aceleração total.",
  "Use Arrive when its acceleration exceeds 1 u/s²; otherwise evaluate Wander.":
      "Usa Arrive quando sua aceleração ultrapassa 1 u/s²; caso contrário avalia Wander.",
  "Reduce desired speed inside the slowing radius and brake near the target.":
      "Reduz a velocidade desejada dentro do raio de desaceleração e freia perto do alvo.",
  "Steering Engine + Flame · Tap to move the target":
      "Steering Engine + Flame · Toque para mover o alvo",
};
