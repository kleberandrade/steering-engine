# Steering engine — aprender movimento autônomo / learn autonomous movement

Esta Wiki explica **a implementação de steering_engine**, do primeiro vetor ao
movimento coletivo. Comece pela intuição, confira o diagrama e só então leia o
pseudocódigo. Cada capítulo também mostra parâmetros, um exemplo em Dart, uma
experiência e limitações. O núcleo é Dart puro; desenhar pertence ao seu jogo.

**English.** Learn this package from vectors to collective motion. Each chapter
contains intuition, a diagram, implementation-oriented pseudocode, tuning, a Dart
configuration, an experiment and limits. Rendering stays in your application.
All pages are bilingual. Shared pseudocode uses the glossary from Foundations.

## Trilha sugerida / Suggested learning path

| Etapa / Stage | Leia / Read | Ao terminar / Outcome |
| --- | --- | --- |
| 1. Base / Basics | [Fundamentos](Foundations.md) | Entender unidades e o loop / understand units and the loop |
| 2. Um destino / One goal | [Seek](Seek.md), [Flee](Flee.md), [Arrive](Arrive.md), [Brake](Brake.md) | Buscar, fugir e parar / approach, escape and stop |
| 3. Antecipação / Anticipation | [Pursuit](Pursuit.md), [Evade](Evade.md), [Wander](Wander.md) | Prever e explorar / predict and explore |
| 4. Decisões / Decisions | [Mistura](Weighted-Blend.md), [Prioridade](Priority-Steering.md) | Combinar sem perder a intenção / compose intentionally |
| 5. Ambiente / Environment | [Trajetória](Path-Following.md), [Obstáculos](Obstacle-Avoidance.md), [Paredes](Wall-Following.md) | Usar geometria local / use local geometry |
| 6. Grupo / Group | [Separação](Separation.md), [Alinhamento](Alignment.md), [Coesão](Cohesion.md), [Flocking](Flocking.md) | Atualizar o bando simultaneamente / update a flock synchronously |
| 7. Organização / Organization | [Líder](Leader-Following.md), [Fila](Queue-Following.md), [Índice espacial](Spatial-Index.md) | Seguir e consultar vizinhos / follow and query neighbors |
| 8. Prática / Practice | [Receitas e diagnóstico](Recipes.md) | Levar ao Flutter/Flame / use in Flutter and Flame |

## O que estudar com cada exemplo / Example map

Execute da raiz do repositório / run from the repository root:

| Comando / Command | Observe / Watch |
| --- | --- |
| `dart run example/steering_engine_example.dart` | Arrive e integração / arrival and integration |
| `dart run example/composition.dart` | Mistura e prioridade / blending and priority |
| `dart run example/path_following.dart` | Troca de waypoint e chegada / transitions and arrival |
| `dart run example/obstacle_avoidance.dart` | Superfícies e desvio / surfaces and avoidance |
| `dart run example/flocking.dart` | Regras locais e grupo / local rules and flock |
| `dart run example/following.dart` | Líder, fila e parede / leader, queue and wall |
| `dart run example/spatial_index.dart` | Equivalência das consultas / query equivalence |

Para ver o movimento / to see motion:

```sh
cd example/flutter_lab
flutter pub get
flutter run -d chrome
```

## Modelo e referências / Model and references

As setas verdes nos diagramas representam decisões locais, **não trajetórias
simuladas nem garantia de ausência de colisão**. O engine integra aceleração,
sem massa, atrito automático, dinâmica de veículo ou planejamento global.
Green arrows show local decisions, not simulated paths or collision guarantees.

Os conceitos seguem Craig Reynolds, mas as equações e contratos de estado nesta
Wiki descrevem esta biblioteca; variantes em outros materiais podem diferir.
The concepts follow Reynolds; the formulas here describe this package’s choices.

- [Reynolds 1999 — Steering Behaviors for Autonomous Characters](https://www.red3d.com/cwr/steer/gdc99/)
- [Reynolds 1987 — Flocks, Herds, and Schools](https://www.red3d.com/cwr/boids/)
- [Equações completas / Detailed conventions](../behaviors.md)
- [Primeiros passos em português](../getting_started.pt-BR.md) · [Getting started](../getting_started.md)
- [Arquitetura / Architecture](../architecture.md)

Fontes versionadas / reviewed sources: `doc/wiki/` no repositório. Atualize essas
fontes primeiro; o espelho da Wiki é preparado com `tool/sync_wiki.py` conforme
[Contribuição](../wiki-maintenance.md).
