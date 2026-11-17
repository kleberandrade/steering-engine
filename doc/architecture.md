# Architecture / Arquitetura

| Layer / Camada | Responsibility / Responsabilidade |
| --- | --- |
| Vec2, SteeringAgent | Immutable values / Valores imutáveis |
| SteeringBehavior | Acceleration contract / Contrato de aceleração |
| Built-in behaviors | Local movement math / Matemática de movimento local |
| WeightedBlend, PrioritySteering | Composition / Composição |
| SteeringEngine | Bounded integration / Integração com limites |
| example/flutter_lab | Clock, rendering, interaction and demo boundaries / Relógio, desenho, interação e bordas do exemplo |

Action selection belongs to the caller. A decision or fuzzy engine can choose or
configure a behavior without becoming a runtime dependency of this package.
Global pathfinding and rendering remain separate concerns.

A escolha de ações pertence ao consumidor. Outros engines podem selecionar ou
configurar os comportamentos sem acoplamento entre packages. O núcleo não assume
Flutter, Flame, relógio global, fronteiras do mundo ou dinâmica de um veículo.

Most behaviors are immutable. Wander owns a private random stream; do not share
it across agents or evaluate it twice to draw a debug vector. The lab samples once
and passes the sampled acceleration through a tiny behavior adapter.

A maioria dos comportamentos é imutável. Wander possui estado privado: use uma
instância por agente. Para desenhar vetores, reutilize a aceleração já calculada.

CircleObstacle and ObstacleThreat are immutable geometry values. ObstacleAvoidance
copies the configuration and exposes a pure threat query; PrioritySteering owns
selection among avoidance and goal following. SteeringEngine remains unchanged.
O desvio calcula aceleração; o integrador não faz correção de colisões ou posições.
See [geometry and limits](obstacle_avoidance.md).

## Source layout / Organização do código

| Directory | Responsibility / Responsabilidade |
| --- | --- |
| `lib/src/core/` | Agent, behavior contract, integration, validation and shared steering math |
| `lib/src/math/` | Immutable vector mathematics |
| `lib/src/behaviors/individual/` | One local movement behavior per file |
| `lib/src/behaviors/group/` | Collective movement and flocking composition |
| `lib/src/composition/` | Weighted and priority orchestration |
| `lib/src/geometry/` | Physical geometry values |
| `lib/src/navigation/` | Waypoint routes, following and obstacle avoidance |
| `lib/src/perception/` | Immutable neighborhood snapshots |
| `example/flutter_lab/lib/lab/` | Lab page, renderer, theme and demo simulation |

Import only `package:steering_engine/steering_engine.dart`; implementation paths
under `src/` are internal and may change. The reorganized source preserves every
existing public class and constructor. / O import público continua igual; os
caminhos internos em `src/` não fazem parte da API de consumo.
