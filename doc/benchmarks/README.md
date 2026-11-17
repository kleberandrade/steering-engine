# Benchmarks / Medições

Native AOT on macOS arm64, Dart 3.11.5. Each strategy/population ran in a fresh
process: 5 warm-up frames and 15 measured frames. A frame includes immutable
observation/index construction, all flocking calculations and motion integration,
with the same seeded fixed-density uniform positions repeated for every sample.
It excludes rendering, Flutter layout, garbage-collection control and live scene
evolution. Checksums are identical for both strategies.

| Agents | Linear median (ms) | Grid median (ms) | Linear/grid | Peak process RSS MiB (linear/grid) |
| --- | --- | --- | --- | --- |
| 100 | 0.88 | 1.11 | 0.80× | 16.03 / 15.56 |
| 500 | 17.02 | 7.07 | 2.41× | 15.67 / 15.91 |
| 1000 | 66.07 | 14.86 | 4.44× | 15.80 / 16.52 |

RSS is process-wide resident memory, including VM/allocator overhead; it is not
an isolated index allocation measurement. Small sample counts, OS scheduling,
cache state and hardware affect both timing and RSS. The raw JSON includes p95,
RSS before/after, SDK and checksum. No performance threshold is imposed in CI.
`baseline_*.json` records the original pre-index code; `linear_*.json` and
`spatial_*.json` are the current comparison. Dense clustering, large query radii
or small populations can make a grid slower. This result is not a universal speedup.

Reproduce from the repository (benchmark tooling is not in the published core):

```sh
dart compile exe benchmark/flocking_benchmark.dart -o /tmp/steering-bench
/tmp/steering-bench 100 15 linear
/tmp/steering-bench 100 15 spatial
/tmp/steering-bench 500 15 linear
/tmp/steering-bench 500 15 spatial
/tmp/steering-bench 1000 15 linear
/tmp/steering-bench 1000 15 spatial
```

## Português

A tabela compara processos separados no mesmo runtime, com a construção do índice
incluída no tempo. Não mede renderização nem garante FPS. O RSS é a memória do
processo inteiro, não o custo isolado de cada estrutura. As somas de verificação
são iguais. Cenas densas, raios grandes e populações pequenas podem eliminar o
ganho; compare as duas opções no laboratório e meça sua própria aplicação.
