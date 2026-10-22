# Relógio digital em VHDL — DE0-Nano

Relógio HH:MM para a placa DE0-Nano (Cyclone IV E — EP4CE22F17C6) com o kit de expansão UFPE/DES, desenvolvido no Quartus II 13.0.

## Arquivos

| Arquivo | Função |
|---|---|
| `teste0.vhd` | Top-level: liga divisor de clock, contadores e display |
| `conta_1seg.vhd` | Divisor do clock de 50 MHz (gera 1 Hz e 400 Hz) |
| `Flip_Flop_JK.vhd` | Flip-flop JK (borda de descida, clear e preset assíncronos ativos em '0') |
| `int_7seg.vhd` | Inteiro 0–9 → 7 segmentos |
| `bin_7seg.vhd` | BCD 4 bits → 7 segmentos |
| `debounce.vhd` | Filtro de 10 ms para os botões, com pulso na borda 1 → 0 |
| `projetos.qpf` / `projetos.qsf` | Projeto Quartus e pinagem |

## Funcionamento

- **Segundos:** contador assíncrono com 6 flip-flops JK em cascata, zerado ao chegar em 60.
- **Display:** 2 flip-flops JK a 400 Hz selecionam qual dos 4 dígitos é mostrado (multiplexação).
- **Minutos/horas:** contadores assíncronos de flip-flops JK em BCD (unidade 0–9, dezena 0–5 / 0–2), cada estágio clocado pelo bit mais alto do anterior; zeram ao chegar em 10, 60 e 24.
- **Ajuste (incremento):** com `ehkey(7)` ligada (segundos parados em 00), cada aperto de `ehkey(8)` soma 1 minuto e cada aperto de `ehkey(9)` soma 1 hora (botões NF: '1' solto, '0' apertado; conta na borda 1 → 0). Os limites são os do próprio contador: minutos 59 → 00 e horas 23 → 00; os minutos virando 59 → 00 também somam 1 na hora. Com `ehkey(7)` desligada os botões não fazem nada.
- **Debounce:** `ehkey(8)` e `ehkey(9)` passam por um filtro de 10 ms (`debounce.vhd`), então o bouncing do contato não gera vários incrementos. `LED(0)`/`LED(1)` mostram o botão dos minutos/horas apertado (já filtrado).

## Como compilar

Abra `projetos.qpf` no Quartus II, compile (Ctrl+L) e grave o `.sof` pelo Programmer.
