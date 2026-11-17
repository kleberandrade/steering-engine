# Equações e convenções

p é posição; v, velocidade; V, velocidade máxima; A, aceleração máxima; T, tempo
de resposta positivo em segundos. `limit(x, m)` limita o módulo sem mudar a
direção. Normalizar o vetor zero retorna zero.

| Comportamento | Velocidade desejada |
| --- | --- |
| Seek | `normalize(alvo - p) * V` |
| Flee | `normalize(p - alvo) * V` |
| Brake | Zero |

A saída é `limit((velocidadeDesejada - v) / T, A)`. Na sobreposição exata, Seek
e Flee solicitam velocidade zero, freando o agente sem inventar uma direção.

Arrive calcula `V * clamp((d - R0) / (R1 - R0), 0, 1)`, com distância d,
raio de parada R0 e raio de desaceleração R1 > R0 >= 0. A frenagem também respeita
A dentro de R0; a velocidade não é zerada instantaneamente.

Pursuit e Evade usam `t = min(maxPrediction, distância / V)` (t = 0 se V = 0),
e preveem `posiçãoAlvo + velocidadeAlvo * t`. Depois buscam ou fogem dessa
posição. É previsão linear com snapshot, sem solução exata de interceptação.

Wander varia um ângulo por uma amostra uniforme em [-1, 1] multiplicada por
`jitter * dt`. O ponto fica em um círculo à frente do agente; a direção acompanha
a velocidade ou +X quando parado. O ângulo é reduzido módulo 2π. `dt == 0` não
altera o ângulo nem consome aleatoriedade. Uma instância por agente, avaliada uma
vez por passo.

WeightedBlend soma `peso * aceleração` e limita a A, sem normalizar os pesos.
Peso zero não avalia o comportamento. PrioritySteering escolhe a primeira saída
com módulo estritamente maior que epsilon e limita a A. Listas vazias retornam
zero; as configurações são copiadas e imutáveis.

A integração usa Euler semi-implícito:

```text
a = limit(comportamento.calculate(agente, dt), A)
vNext = limit(v + a * dt, V)
pNext = p + vNext * dt
```

O engine não cria subpassos, colisões, atrito ou massa. `dt == 0` devolve o mesmo
snapshot sem avaliar comportamentos. As validações funcionam sem asserts.
Vetores precisam ter componentes e módulo finitos; overflow gera erro em vez de
propagar estado inválido. Use unidades consistentes e passos pequenos e fixos.

## Static obstacle avoidance / Desvio de obstáculos estáticos

See [the bilingual geometry guide](obstacle_avoidance.md) for expanded circle
radii, ray entry selection, overlap response, braking and numerical limits.
Consulte o guia bilíngue para as equações e limitações do desvio circular.
