--BIBLIOTECAS USADAS PARA REALIZAÇÃO DO PROGRAMA
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity teste1 is
	port
	(
	   -- ENTRADAS FISICAS!
		-- Obs:Não existe necessidade de modificar nada aqui!!!

		--DE0Nano
		-- Input ports
		CLOCK_50 : in std_logic; -- Oscilador
		KEY : in std_logic_vector( 1 downto 0); --Botões que ficam na placa DE0-nano

		--output ports
		LED : out std_logic_vector(7 downto 0); --LEDS que ficam na placa DEO-nano

		--Expansion Header UFPE/DES kit
		-- input ports
		ehkey : in std_logic_vector(9 downto 0);-- bits 0-7=>chaves; bits 8 e 9 => pushbutton

		-- output ports
		dig7seg : out std_logic_vector(1 downto 0); -- Seletor do display
		d7seg : out std_logic_vector(8 downto 0) -- Indicator de 7seg selecionado por dig7seg

	);
end teste1;


architecture behaviorOfTest of teste1 is
--Colocar aqui todas os sinais que deseja utilizar("equivalentes a variaveis auxiliares")
--Exemplos de declaração de sinal:
--signal var_auxiliar: std_logic;
--signal vars_auxiliares: std_logic_vector(3 downto 0);
signal seg,dseg : std_logic_vector(1 downto 0);
signal saida: std_logic_vector(1 downto 0);
signal saidaseg: std_logic_vector(5 downto 0);
signal minBCDuni, segBCDUni,segBCDDez,minBCDDez  : std_logic_vector (6 downto 0);
signal rst_segundos: std_logic;

-- Saidas (Q) dos JKs de cada digito, em BCD
signal segUni  : std_logic_vector(3 downto 0); -- 0 a 9
signal segDez  : std_logic_vector(2 downto 0); -- 0 a 5
signal minUni : std_logic_vector(3 downto 0); -- 0 a 9
signal minDez : std_logic_vector(2 downto 0); -- 0 a 6
signal segUni4, segDez4, minUni4, minDez4: std_logic_vector(3 downto 0); -- digitos em 4 bits para o bin_7seg

-- Clear (ativo em '0') de cada JK
signal segUniClr  : std_logic;
signal segDezClr  : std_logic;
signal minUniClr : std_logic;
signal minDezClr : std_logic;

-- Condicoes de zerar a contagem (vira de 9->0, 5->0 e 23->00)
signal zera_segUni, zera_segDez, zera_minUni, zera_minDez: std_logic := '0';

-- Botoes ehkey(8)/ehkey(9) pós filtro
signal bot_seg_db, bot_min_db: std_logic;       
signal apertou_seg, apertou_min: std_logic;     

signal inc_seg, inc_min: std_logic := '0';
-- Clock da unidade dos segundos/minutos: contagem normal XOR pulso de incremento
signal clk_segUni, clk_minUni: std_logic;

begin--PROGRAMAÇÂO... lembre-se a programação fica depois do begin da arquitetura...

dig7seg <= saida;


DEB_SEG: entity work.debounce
port map (clk => CLOCK_50, entrada => ehkey(8), saida => bot_seg_db,  apertou => apertou_seg);
DEB_MIN: entity work.debounce
port map (clk => CLOCK_50, entrada => ehkey(9), saida => bot_min_db, apertou => apertou_min);

-- Pulso de incremento registrado (sem glitch) e liberado so com ehkey(7) = '1'
process(CLOCK_50)
begin
	if rising_edge(CLOCK_50) then
		inc_seg  <= apertou_seg  and ehkey(7);
		inc_min <= apertou_min and ehkey(7);
	end if;
end process;

-- O pulso de incremento passado por XOR no clock gera exatamente
-- uma borda de descida, no caso essa borda depois é utilizada no FF seg e min em cascata presente.
clk_segUni  <= saidaseg(5) xor inc_seg;
clk_minUni <= segDez(2)   xor inc_min;


segundo: entity work.conta_1seg
port map (clk => clocK_50,frequencia => 1, pulso => seg(0));

khz: entity work.conta_1seg
port map (clk => clocK_50,frequencia => 400, pulso => seg(1));

-- contador para a variaçao do display 7seg

FLIP_FLOP0: entity work.Flip_Flop_JK							
port map(J => '1', K => '1', Clk => seg(1), Clr => '1',	Q => saida(0));
FLIP_FLOP1: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => saida(0),Clr => '1', Q => saida(1));



-- Condicoes de zerar registradas no CLOCK_50: o clear fica ativo por pelo menos 1 ciclo,
-- ate todos os bits estarem em 0. Com o clear combinacional ele sumia assim que o bit 1
-- zerava, e a borda de descida do bit 1 ainda fazia o bit 2 virar (9 -> 10 mostrava 4).
process(CLOCK_50)
begin
	if rising_edge(CLOCK_50) then
		zera_segUni <= segUni(3) and segUni(1); -- chegou em 10
		zera_segDez <= segDez(2) and segDez(1); -- chegou em 6
		zera_minDez    <= minDez(1) and minDez(2); -- chegou em 6
		zera_minUni <= (minUni(3) and minUni(1)); -- chegou em 10 ou 24
	end if;
end process;

-- UNIDADE DOS SEGUNDOS: 0 a 9, clock = saidaseg(5) (cai na virada 59 -> 0 s) ou aperto de ehkey(8)
segUniClr <= (not zera_segUni);

segUniC0: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => clk_segUni,  Clr => segUniClr, Q => segUni(0));
segUniC1: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => segUni(0),   Clr => segUniClr, Q => segUni(1));
segUniC2: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => segUni(1),   Clr => segUniClr, Q => segUni(2));
segUniC3: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => segUni(2),   Clr => segUniClr, Q => segUni(3));

-- DEZENA DOS SEGUNDOS: 0 a 5, clock = segUni(3) (cai na virada 9 -> 0)
segDezClr <= ( not zera_segDez);

segDezC0: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => segUni(3), Clr => segDezClr, Q => segDez(0));
segDezC1: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => segDez(0), Clr => segDezClr, Q => segDez(1));
segDezC2: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => segDez(1), Clr => segDezClr, Q => segDez(2));

-- UNIDADE DOS MINUTOS: 0 a 9, clock = segDez(2) (cai na virada 59 -> 00 seg) ou aperto de ehkey(9)
minUniClr <= (not zera_minUni);

minUniC0: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => clk_minUni, Clr => minUniClr, Q => minUni(0));
minUniC1: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => minUni(0), Clr => minUniClr, Q => minUni(1));
minUniC2: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => minUni(1), Clr => minUniClr, Q => minUni(2));
minUniC3: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => minUni(2), Clr => minUniClr, Q => minUni(3));

-- DEZENA DOS MINUTOS: 0 a 6, clock = minUni(3) (cai na virada 9 -> 0)
minDezClr <= (not zera_minDez);

minDezC0: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => minUni(3), Clr => minDezClr, Q => minDez(0));
minDezC1: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => minDez(0), Clr => minDezClr, Q => minDez(1));
minDezC2: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => minDez(1), Clr => minDezClr, Q => minDez(2));


-- Digitos para o display (bin_7seg apaga o digito se o valor for invalido, e ajusta para todos os vetores possuam 4 bits.
segUni4  <= segUni;
segDez4  <= '0' & segDez;
minUni4 <= minUni;
minDez4 <= '0' & minDez;

BCDsegUni: entity work.bin_7seg
port map (bin => segUni4, seg => segBCDUni);
BCDsegDez: entity work.bin_7seg
port map (bin => segDez4, seg => segBCDDez);

BCDminuni: entity work.bin_7seg
port map (bin => minUni4, seg => minBCDuni);
BCDmindez: entity work.bin_7seg
port map (bin => minDez4, seg => minBCDDez);



process(saida, segBCDUni, segBCDDez, minBCDuni, minBCDDez)
begin
	case saida is
		when "00"   => d7seg(7 downto 1) <= minBCDDez;
		when "01"   => d7seg(7 downto 1) <= segBCDDez;
		when "10"   => d7seg(7 downto 1) <= minBCDuni;
		when others => d7seg(7 downto 1) <= segBCDUni;
	end case;
end process;

end behaviorOfTest;
