--BIBLIOTECAS USADAS PARA REALIZAÇÃO DO PROGRAMA
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity teste0 is
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
end teste0;


architecture behaviorOfTest of teste0 is
--Colocar aqui todas os sinais que deseja utilizar("equivalentes a variaveis auxiliares")
--Exemplos de declaração de sinal:
--signal var_auxiliar: std_logic;
--signal vars_auxiliares: std_logic_vector(3 downto 0);
signal seg,dseg : std_logic_vector(1 downto 0);
signal saida: std_logic_vector(1 downto 0);
signal minBCDUni, minBCDDez, horaBCDUni, horaBCDDez : std_logic_vector (6 downto 0);

-- Saidas (Q) dos JKs de cada digito, em BCD
signal minUni : std_logic_vector(3 downto 0); -- 0 a 9
signal minDez : std_logic_vector(2 downto 0); -- 0 a 5
signal horaUni : std_logic_vector(3 downto 0); -- 0 a 9
signal horaDez : std_logic_vector(2 downto 0); -- 0 a 5
signal minUni4, minDez4, horaUni4, horaDez4: std_logic_vector(3 downto 0); -- digitos em 4 bits para o bin_7seg

-- Clear (ativo em '0') de cada JK
signal minUniClr : std_logic_vector(3 downto 0);
signal minDezClr : std_logic_vector(2 downto 0);
signal horaUniClr : std_logic_vector(3 downto 0);
signal horaDezClr : std_logic_vector(2 downto 0);

-- Condicoes de zerar a contagem (vira de 9->0 e 5->0)
signal zera_minUni, zera_minDez, zera_horaUni, zera_horaDez: std_logic;

-- Botoes ehkey(8)/ehkey(9) pós filtro
signal bot_min_db, bot_hora_db: std_logic;
signal apertou_min, apertou_hora: std_logic;

signal inc_min, inc_hora: std_logic := '0';
-- '1' = contagem dos minutos liberada (so muda com seg(0) = '0', para nao gerar borda falsa)
signal conta: std_logic := '1';
-- Clock da unidade dos minutos/horas: contagem normal XOR pulso de incremento
signal clk_minUni, clk_horaUni: std_logic;
begin--PROGRAMAÇÂO... lembre-se a programação fica depois do begin da arquitetura...

dig7seg <= saida;

-- AJUSTE: ehkey(7) = '1' para a contagem; cada aperto de ehkey(8) soma 1 minuto
-- e cada aperto de ehkey(9) soma 1 hora.
DEB_MIN: entity work.debounce
port map (clk => CLOCK_50, entrada => ehkey(8), saida => bot_min_db, apertou => apertou_min);
DEB_HORA: entity work.debounce
port map (clk => CLOCK_50, entrada => ehkey(9), saida => bot_hora_db, apertou => apertou_hora);

-- Pulso de incremento registrado (sem glitch) e liberado so com ehkey(7) = '1'
process(CLOCK_50)
begin
	if rising_edge(CLOCK_50) then
		inc_min <= apertou_min and ehkey(7);
		inc_hora <= apertou_hora and ehkey(7);
		if seg(0) = '0' then
			conta <= not ehkey(7);
		end if;
	end if;
end process;

-- O pulso de incremento passado por XOR no clock gera exatamente
-- uma borda de descida, no caso essa borda depois é utilizada no FF min e hora em cascata presente.
clk_minUni <= (seg(0) and conta) xor inc_min;
clk_horaUni <= minDez(2) xor inc_hora;


segundo: entity work.conta_1seg
port map (clk => clocK_50,frequencia => 1, pulso => seg(0));

khz: entity work.conta_1seg
port map (clk => clocK_50,frequencia => 400, pulso => seg(1));

-- contador para a variaçao do display 7seg

FLIP_FLOP0: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => seg(1), Clr => '1',	Q => saida(0));
FLIP_FLOP1: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => saida(0),Clr => '1', Q => saida(1));


-- UNIDADE DOS MINUTOS: 0 a 9, clock = seg(0) (1 Hz, parado no ajuste) ou aperto de ehkey(8)
zera_minUni <= minUni(3) and minUni(1); -- chegou em 10
minUniClr <= (others => not zera_minUni);

minUniC0: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => clk_minUni, Clr => minUniClr(0), Q => minUni(0));
minUniC1: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => minUni(0),  Clr => minUniClr(1), Q => minUni(1));
minUniC2: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => minUni(1),  Clr => minUniClr(2), Q => minUni(2));
minUniC3: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => minUni(2),  Clr => minUniClr(3), Q => minUni(3));

-- DEZENA DOS MINUTOS: 0 a 5, clock = minUni(3) (cai na virada 9 -> 0)
zera_minDez <= minDez(2) and minDez(1); -- chegou em 6
minDezClr <= (others => not zera_minDez);

minDezC0: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => minUni(3), Clr => minDezClr(0), Q => minDez(0));
minDezC1: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => minDez(0), Clr => minDezClr(1), Q => minDez(1));
minDezC2: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => minDez(1), Clr => minDezClr(2), Q => minDez(2));

-- UNIDADE DAS HORAS: 0 a 9, clock = minDez(2) (cai na virada 59 -> 00 min) ou aperto de ehkey(9)
zera_horaUni <= horaUni(3) and horaUni(1); -- chegou em 10
horaUniClr <= (others => not zera_horaUni);

horaUniC0: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => clk_horaUni, Clr => horaUniClr(0), Q => horaUni(0));
horaUniC1: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => horaUni(0),  Clr => horaUniClr(1), Q => horaUni(1));
horaUniC2: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => horaUni(1),  Clr => horaUniClr(2), Q => horaUni(2));
horaUniC3: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => horaUni(2),  Clr => horaUniClr(3), Q => horaUni(3));

-- DEZENA DAS HORAS: 0 a 5, clock = horaUni(3) (cai na virada 9 -> 0); 59:59 -> 00:00
zera_horaDez <= horaDez(2) and horaDez(1); -- chegou em 6
horaDezClr <= (others => not zera_horaDez);

horaDezC0: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => horaUni(3), Clr => horaDezClr(0), Q => horaDez(0));
horaDezC1: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => horaDez(0), Clr => horaDezClr(1), Q => horaDez(1));
horaDezC2: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => horaDez(1), Clr => horaDezClr(2), Q => horaDez(2));


-- Digitos para o display (bin_7seg apaga o digito se o valor for invalido, e ajusta para todos os vetores possuam 4 bits.
minUni4 <= minUni;
minDez4 <= '0' & minDez;
horaUni4 <= horaUni;
horaDez4 <= '0' & horaDez;

BCDminUni: entity work.bin_7seg
port map (bin => minUni4, seg => minBCDUni);
BCDminDez: entity work.bin_7seg
port map (bin => minDez4, seg => minBCDDez);

BCDhoraUni: entity work.bin_7seg
port map (bin => horaUni4, seg => horaBCDUni);
BCDhoraDez: entity work.bin_7seg
port map (bin => horaDez4, seg => horaBCDDez);



process(saida, minBCDUni, minBCDDez, horaBCDUni, horaBCDDez)
begin
	case saida is
		when "00"   => d7seg(7 downto 1) <= horaBCDDez;
		when "01"   => d7seg(7 downto 1) <= minBCDDez;
		when "10"   => d7seg(7 downto 1) <= horaBCDUni;
		when others => d7seg(7 downto 1) <= minBCDUni;
	end case;
end process;

end behaviorOfTest;
