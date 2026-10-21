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
| `projetos.qpf` / `projetos.qsf` | Projeto Quartus e pinagem |

## Funcionamento

- **Segundos:** contador assíncrono com 6 flip-flops JK em cascata, zerado ao chegar em 60.
- **Display:** 2 flip-flops JK a 400 Hz selecionam qual dos 4 dígitos é mostrado (multiplexação).
- **Minutos/horas:** contadores assíncronos de flip-flops JK em BCD (unidade 0–9, dezena 0–5 / 0–2), cada estágio clocado pelo bit mais alto do anterior; zeram ao chegar em 10, 60 e 24.
- **Ajuste (preset):** coloque o valor nas chaves em BCD — `ehkey(6..4)` = dezena (3 bits), `ehkey(3..0)` = unidade; `ehkey(7)` habilita o ajuste. Com `ehkey(7)` ligada, pressione `ehkey(8)` (botão NF: '1' solto, '0' apertado) para carregar os minutos (zera os segundos) e depois `ehkey(9)` para carregar as horas. Cada botão carrega dezena e unidade juntas. Enquanto o botão está pressionado, cada JK recebe Pre='0' (chave em 1) ou Clr='0' (chave em 0).
- **Intertravamento:** com `ehkey(7)` desligada os botões não fazem nada; os dois botões juntos não carregam nada, e a carga só acontece com valor válido (minutos 00–59, horas 00–23). `LED(0)`/`LED(1)` acende quando o botão dos minutos/horas está pressionado mas a carga foi bloqueada.

## Como compilar

Abra `projetos.qpf` no Quartus II, compile (Ctrl+L) e grave o `.sof` pelo Programmer.
