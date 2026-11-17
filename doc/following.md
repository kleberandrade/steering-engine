# Following behaviors / Comportamentos de seguimento

| Behavior | Public API | What it does |
| --- | --- | --- |
| Path following | `FollowPath(SteeringPath(...))` | Visits ordered waypoint capture regions and arrives at the final point or loops |
| Leader following | `LeaderFollowing(leader)` | Arrives at a trailing target with local leader clearance taking precedence |
| Queue | `QueueFollowing(observed, movement: goal)` | Filters requested movement to brake behind the nearest forward lane occupant |
| Wall following | `WallFollowing(walls)` | Seeks a projected tangential target at a chosen wall offset |

## Path

This was already implemented. Keep one follower per agent; the path geometry can
be shared. It is waypoint capture, not continuous closest-segment path projection.
See [path following](path_following.md) and `example/path_following.dart`.

## Leader

```dart
final following = LeaderFollowing(leaderSnapshot,
  distance: 60, avoidanceRadius: 15,
);
```

The target is `leader.position - normalizedHeading * distance`. A stopped leader
uses the supplied `fallbackDirection`, or +X. Preserve the last heading in your
own observations if needed. Clearance uses the existing circle avoidance before
Arrive; zero radius disables it. Distance must exceed the clearance radius.
Recreate when the leader changes. Following itself returns zero acceleration.
This does not synchronize formation slots or guarantee inter-follower clearance;
compose Separation when a group follows one leader.

## Queue

```dart
final queued = QueueFollowing(observed,
  movement: Arrive(destination), direction: Vec2(1, 0),
  spacing: 25, laneRadius: 10, lookAhead: 100,
);
```

The fixed normalized lane direction is +X by default. Candidates must be strictly
ahead, within lookAhead and within the lateral lane radius. The nearest forward
occupant sets a desired speed:

`clamp(blockerForwardSpeed + (gap-spacing)/responseTime, 0, maxSpeed)`.

Requested forward acceleration is capped by the response needed to approach that
speed. Requested lateral acceleration is retained, then the whole result is
bounded by maxAcceleration. Movement is evaluated once. This decorator can hold
a stopped agent at the requested gap without allowing a competing goal to start
it every frame. Rebuild observations when occupants move or leave.

Spacing is center-to-center. Exact coincident positions invent no ordering.
This is a local spatial queue, not a job queue, fairness protocol or global FIFO
reservation. Late detection/insufficient braking can still produce contact.

## Walls

```dart
final rule = WallFollowing([
  WallSegment(Vec2(0, 0), Vec2(1000, 0)),
], wallOffset: 20, lookAhead: 30, side: WallSide.left);
```

A probe is placed ahead of current velocity, or fallbackDirection when stopped.
Select the nearest finite segment within maxDistance and clamp its projection
to the endpoints. Orient its tangent to current travel, then seek:

`projectedProbe + tangent * lookAhead + sideNormal * wallOffset`.

Left means the normal `(-tangent.y, tangent.x)`; right means its opposite. It
specifies the agent's offset relative to the oriented segment, not which wall
lies physically left in screen coordinates. Ties preserve input order.

`targetFor(agent)` is a pure debug query. Empty/distant geometry returns zero.
Walls are copied, finite and nondegenerate. Local segment changes can oscillate
at sharp corners; endpoints are not a route planner. No contact solver or hard
clearance constraint is added to the integrator.

## Português

Path following já existia e usa captura de waypoints. Leader following chega a
um alvo atrás do líder e dá prioridade ao seu afastamento local. O líder é um
snapshot: recrie o comportamento quando ele mudar; parado, use a última direção
conhecida como fallback se necessário.

QueueFollowing envolve outro comportamento de movimento e limita sua aceleração
para frente conforme o ocupante mais próximo na faixa. A direção da fila é fixa,
a distância é entre centros e a observação deve ser atualizada por quadro.
Ele não implementa justiça, tarefas concorrentes ou reserva FIFO global.

WallFollowing projeta um ponto à frente em segmentos finitos e busca um alvo
tangencial com afastamento configurado. O lado usa a normal matemática do
segmento orientado. A seleção de quinas é local: pode oscilar e não substitui
planejamento global nem resolução física de colisões.

Os quatro modos têm testes e demonstrações. Execute `dart run example/following.dart`
e compare os modos Leader following, Queue e Wall following no laboratório.
