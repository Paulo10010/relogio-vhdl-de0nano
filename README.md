# Relógio digital em VHDL — DE0-Nano

Relógio HH:MM para a placa DE0-Nano (Cyclone IV E — EP4CE22F17C6) com o kit de expansão UFPE/DES, desenvolvido no Quartus II 13.0.

## Arquivos

| Arquivo | Função |
|---|---|
| `teste0.vhd` | Top-level: liga divisor de clock, contadores e display |
| `conta_1seg.vhd` | Divisor do clock de 50 MHz (gera 1 Hz e 400 Hz) |
| `Flip_Flop_JK.vhd` | Flip-flop JK (borda de descida, clear assíncrono ativo em '0') |
| `int_7seg.vhd` | Inteiro 0–9 → 7 segmentos |
| `bin_7seg.vhd` | BCD 4 bits → 7 segmentos |
| `projetos.qpf` / `projetos.qsf` | Projeto Quartus e pinagem |

## Funcionamento

- **Segundos:** contador assíncrono com 6 flip-flops JK em cascata, zerado ao chegar em 60.
- **Display:** 2 flip-flops JK a 400 Hz selecionam qual dos 4 dígitos é mostrado (multiplexação).
- **Minutos/horas:** contadores em cascata acionados pelo vai-um do estágio anterior.
- **Configuração:** chave `ehkey(7)` ativa o modo de ajuste; botões `ehkey(8)` (minuto) e `ehkey(9)` (hora).

## Como compilar

Abra `projetos.qpf` no Quartus II, compile (Ctrl+L) e grave o `.sof` pelo Programmer.
