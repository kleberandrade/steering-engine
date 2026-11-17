# Primeiros passos

1. Adicione a dependência por caminho do README e execute `dart pub get`.
2. Crie um `SteeringAgent` com posição e limites de velocidade e aceleração.
3. Comece com `Arrive` para observar aproximação e frenagem.
4. Chame `SteeringEngine.step` usando um passo pequeno em **segundos**.
5. Guarde o snapshot retornado e desenhe a posição.

O engine não controla relógio, mundo ou renderização. No Flutter, acumule o tempo
do Ticker e execute passos fixos, como no laboratório. No Flame, use `update(dt)`
para alimentar seu acumulador e copie a posição resultante para o componente.

| Sintoma | Verificação |
| --- | --- |
| Movimento rápido demais | Converta milissegundos para segundos |
| O agente ultrapassa o alvo | Use Arrive e reduza o passo de tempo |
| Agentes compartilham o mesmo Wander | Crie uma instância por agente |
| Pursuit usa uma posição antiga | Atualize o snapshot do alvo |
| A combinação nunca para | Wander pode continuar pedindo movimento |
| Aceleração zero e agente em movimento | A velocidade existente é preservada |

Execute os exemplos em `example/` e experimente o laboratório Flutter.
