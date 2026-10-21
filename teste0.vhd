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
signal saidaseg: std_logic_vector(5 downto 0);
signal horaBCDuni, minBCDUni,minBCDDez,horaBCDDez  : std_logic_vector (6 downto 0);
signal rst_segundos: std_logic;

-- Saidas (Q) dos JKs de cada digito, em BCD
signal minUni  : std_logic_vector(3 downto 0); -- 0 a 9
signal minDez  : std_logic_vector(2 downto 0); -- 0 a 5
signal horaUni : std_logic_vector(3 downto 0); -- 0 a 9
signal horaDez : std_logic_vector(1 downto 0); -- 0 a 2
signal minUni4, minDez4, horaUni4, horaDez4: std_logic_vector(3 downto 0); -- digitos em 4 bits para o bin_7seg

-- Preset e clear (ativos em '0') de cada JK
signal minUniPre,  minUniClr  : std_logic_vector(3 downto 0);
signal minDezPre,  minDezClr  : std_logic_vector(2 downto 0);
signal horaUniPre, horaUniClr : std_logic_vector(3 downto 0);
signal horaDezPre, horaDezClr : std_logic_vector(1 downto 0);

-- Condicoes de zerar a contagem (vira de 9->0, 5->0 e 23->00)
signal zera_minUni, zera_minDez, zera_horaUni, zera_24h: std_logic;

-- '1' enquanto o botao de carga estiver pressionado (e a carga for permitida)
signal carga_min, carga_hora: std_logic;

-- Valor das chaves: unidade em 4 bits (0 a 9) e dezena em 3 bits (0 a 5 / 0 a 2)
signal chave_uni: unsigned(3 downto 0);
signal chave_dez: unsigned(2 downto 0);
signal min_valido, hora_valido: std_logic;
begin--PROGRAMAÇÂO... lembre-se a programação fica depois do begin da arquitetura...

dig7seg <= saida;

-- AJUSTE DA HORA POR PRESET
-- Chaves: ehkey(6..4) = dezena (3 bits) e ehkey(3..0) = unidade (4 bits), em BCD.
-- ehkey(7) nao e usada.
-- Botao ehkey(8) carrega os minutos (MM) e ehkey(9) carrega as horas (HH):
-- cada botao carrega a dezena E a unidade de uma vez.
-- Botoes NF (normalmente fechados): '0' em repouso e '1' quando pressionados.
-- Enquanto o botao esta pressionado, cada JK e forcado para o bit da sua chave:
--   chave = '1' => Pre = '0' (Q vai para 1)
--   chave = '0' => Clr = '0' (Q vai para 0)
-- Ajuste primeiro os minutos e depois as horas (carregar os minutos pode gerar
-- um tique na hora, que e sobrescrito na carga da hora).
--
-- INTERTRAVAMENTO:
--  1) Os dois botoes juntos nao carregam nada (as chaves sao as mesmas para os dois).
--  2) So carrega se o valor das chaves for valido: minutos 00 a 59, horas 00 a 23.
--     Sem isso, um valor como 7x ou 25 faz o "zera" (Clr) brigar com o Pre
--     e os digitos ficam oscilando/apagados.
--  O LED(0) / LED(1) acende quando o botao dos minutos / horas esta pressionado
--  mas a carga foi bloqueada.
chave_uni <= unsigned(ehkey(3 downto 0));
chave_dez <= unsigned(ehkey(6 downto 4));

min_valido  <= '1' when chave_uni <= 9 and chave_dez <= 5 else '0';
hora_valido <= '1' when (chave_dez <= 1 and chave_uni <= 9) or
                        (chave_dez = 2  and chave_uni <= 3) else '0';

carga_min  <= ehkey(8) and not ehkey(9) and min_valido;
carga_hora <= ehkey(9) and not ehkey(8) and hora_valido;


segundo: entity work.conta_1seg
port map (clk => clocK_50,frequencia => 1, pulso => seg(0));

khz: entity work.conta_1seg
port map (clk => clocK_50,frequencia => 400, pulso => seg(1));

-- contador para a variaçao do display 7seg

FLIP_FLOP0: entity work.Flip_Flop_JK							--OBS: O clock do flip flop é comandado pelo botão
port map(J => '1', K => '1', Clk => seg(1), Clr => '1',	Q => saida(0));
FLIP_FLOP1: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => saida(0),Clr => '1', Q => saida(1));

-- Os segundos zeram ao chegar em 60 e tambem durante a carga dos minutos.
rst_segundos <= not ((saidaseg(5) and saidaseg(4) and saidaseg(3) and saidaseg(2)) or carga_min);
-- contagem de 0 a 60.
segundoC0: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => seg(0), Clr => rst_segundos,	Q => saidaseg(0));
segundoC1: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => saidaseg(0), Clr => rst_segundos,	Q => saidaseg(1));
segundoC2: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => saidaseg(1), Clr => rst_segundos,	Q => saidaseg(2));
segundoC3: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => saidaseg(2), Clr => rst_segundos, 	Q => saidaseg(3));
segundoC4: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => saidaseg(3), Clr => rst_segundos,	Q => saidaseg(4));
segundoC5: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => saidaseg(4), Clr => rst_segundos,	Q => saidaseg(5));


-- UNIDADE DOS MINUTOS: 0 a 9, clock = saidaseg(5) (cai na virada 59 -> 0 s)
zera_minUni <= minUni(3) and minUni(1); -- chegou em 10
PRESET_MINUNI: for i in 0 to 3 generate
	minUniPre(i) <= not (carga_min and ehkey(i));
	minUniClr(i) <= not ((carga_min and not ehkey(i)) or zera_minUni);
end generate;

minUniC0: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => saidaseg(5), Clr => minUniClr(0), Pre => minUniPre(0), Q => minUni(0));
minUniC1: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => minUni(0),   Clr => minUniClr(1), Pre => minUniPre(1), Q => minUni(1));
minUniC2: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => minUni(1),   Clr => minUniClr(2), Pre => minUniPre(2), Q => minUni(2));
minUniC3: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => minUni(2),   Clr => minUniClr(3), Pre => minUniPre(3), Q => minUni(3));

-- DEZENA DOS MINUTOS: 0 a 5, clock = minUni(3) (cai na virada 9 -> 0)
zera_minDez <= minDez(2) and minDez(1); -- chegou em 6
PRESET_MINDEZ: for i in 0 to 2 generate
	minDezPre(i) <= not (carga_min and ehkey(i+4));
	minDezClr(i) <= not ((carga_min and not ehkey(i+4)) or zera_minDez);
end generate;

minDezC0: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => minUni(3), Clr => minDezClr(0), Pre => minDezPre(0), Q => minDez(0));
minDezC1: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => minDez(0), Clr => minDezClr(1), Pre => minDezPre(1), Q => minDez(1));
minDezC2: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => minDez(1), Clr => minDezClr(2), Pre => minDezPre(2), Q => minDez(2));

-- UNIDADE DAS HORAS: 0 a 9, clock = minDez(2) (cai na virada 59 -> 00 min)
zera_24h     <= horaDez(1) and horaUni(2); -- chegou em 24
zera_horaUni <= (horaUni(3) and horaUni(1)) or zera_24h; -- chegou em 10 ou 24
PRESET_HORAUNI: for i in 0 to 3 generate
	horaUniPre(i) <= not (carga_hora and ehkey(i));
	horaUniClr(i) <= not ((carga_hora and not ehkey(i)) or zera_horaUni);
end generate;

horaUniC0: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => minDez(2),  Clr => horaUniClr(0), Pre => horaUniPre(0), Q => horaUni(0));
horaUniC1: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => horaUni(0), Clr => horaUniClr(1), Pre => horaUniPre(1), Q => horaUni(1));
horaUniC2: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => horaUni(1), Clr => horaUniClr(2), Pre => horaUniPre(2), Q => horaUni(2));
horaUniC3: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => horaUni(2), Clr => horaUniClr(3), Pre => horaUniPre(3), Q => horaUni(3));

-- DEZENA DAS HORAS: 0 a 2, clock = horaUni(3) (cai na virada 9 -> 0)
PRESET_HORADEZ: for i in 0 to 1 generate
	horaDezPre(i) <= not (carga_hora and ehkey(i+4));
	horaDezClr(i) <= not ((carga_hora and not ehkey(i+4)) or zera_24h);
end generate;

horaDezC0: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => horaUni(3), Clr => horaDezClr(0), Pre => horaDezPre(0), Q => horaDez(0));
horaDezC1: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => horaDez(0), Clr => horaDezClr(1), Pre => horaDezPre(1), Q => horaDez(1));


-- Digitos para o display (bin_7seg apaga o digito se o valor for invalido)
minUni4  <= minUni;
minDez4  <= '0' & minDez;
horaUni4 <= horaUni;
horaDez4 <= "00" & horaDez;

BCDminUni: entity work.bin_7seg
port map (bin => minUni4, seg => minBCDUni);
BCDminDez: entity work.bin_7seg
port map (bin => minDez4, seg => minBCDDez);

BCDhorauni: entity work.bin_7seg
port map (bin => horaUni4, seg => horaBCDuni);
BCDhoradez: entity work.bin_7seg
port map (bin => horaDez4, seg => horaBCDDez);



process(saida, minBCDUni, minBCDDez, horaBCDuni, horaBCDDez)
begin
	case saida is
		when "00"   => d7seg(7 downto 1) <= minBCDUni;
		when "01"   => d7seg(7 downto 1) <= minBCDDez;
		when "10"   => d7seg(7 downto 1) <= horaBCDuni;
		when others => d7seg(7 downto 1) <= horaBCDDez;
	end case;
end process;

d7seg(8) <= '0'; -- bits nao usados (ajustar conforme a polaridade do kit)
d7seg(0) <= '0';
LED(0) <= ehkey(8) and not carga_min;  -- carga dos minutos bloqueada
LED(1) <= ehkey(9) and not carga_hora; -- carga das horas bloqueada
LED(7 downto 2) <= (others => '0');
end behaviorOfTest;
