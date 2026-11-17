# Spatial neighborhood lookup / Busca espacial

`AgentNeighborhood(agents)` remains the linear reference implementation.
`AgentNeighborhood.spatial(agents, cellSize: 80)` builds a uniform grid for the
same immutable frame and can be passed to every existing group behavior:

```dart
final observed = AgentNeighborhood.spatial(agents, cellSize: 80);
final rule = Flocking(observed);
agents = [for (final a in agents)
  const SteeringEngine().step(a, rule, 1 / 60)];
```

The grid selects candidate cells, sorts source ordinals, then applies the same
exact Euclidean distance and identity filter as the linear query. Results retain
the same input order, including exact boundaries, duplicate-reference removal
and self exclusion. Flocking therefore receives the same operands in the same
order. Build the index once per frame, not once per agent.

A conservative, scale-aware padding covers floating-point cell boundaries.
Queries whose cell traversal would exceed a simple linear scan fall back to that
scan. Coordinate scales unsafe for exact cross-platform integer cells also use
linear lookup; `usesSpatialIndex` reports whether a grid could be built. Finite,
positive cell size is required. Large radius, high density and many agents in
one cell may erase the gain. Sorting candidates preserves order but has a cost.
There is no universal linear-time whole-flock guarantee.

See the [measured benchmark report](benchmarks/README.md). The lab can switch
between strategies for 24, 100, 500 or 1000 agents. Its physics time covers the
simulation tick only, excluding paint/layout. Browser clocks and hardware differ.
The demo discards excess catch-up after three ticks to remain responsive under
load, so simulated time can lag wall-clock time.

## Português

O construtor original continua sendo a referência linear. O construtor `.spatial`
monta uma grade imutável por quadro, com os mesmos filtros exatos e a mesma ordem
de resultados. Use-o nos comportamentos existentes sem mudar o restante da API.

Células candidatas reduzem o trabalho em cenas adequadas; distâncias grandes,
aglomerações e o custo de construir/consultar a grade podem eliminar o ganho.
Escalas numéricas inseguras e consultas mais caras que uma varredura retornam à
busca linear. Os testes comparam vizinhos e acelerações completas nas duas buscas.

O laboratório permite escolher população e índice. O tempo exibido mede a física
do passo, sem renderização. A atualização tem no máximo três passos de recuperação
por frame e descarta o excedente; isso não é uma promessa de tempo real.
