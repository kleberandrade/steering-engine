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
