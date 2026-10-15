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
signal minUni, minDez: integer range 0 to 9;
signal horaUni, horaDez: integer range 0 to 9;
signal clk_min, clk_hora, fim_hora: std_logic; -- clocks em cascata dos minutos e horas
signal horaBCDuni, minBCDUni,minBCDDez,horaBCDDez  : std_logic_vector (6 downto 0);
signal rst_segundos: std_logic;
signal configuracao: std_logic;
signal horaplus, minplus: std_logic;
begin--PROGRAMAÇÂO... lembre-se a programação fica depois do begin da arquitetura...

--process(configuracao)
--begin
--	if configuracao= '1' then
--		if minplus = '0' then
--			minuni <= minuni + 1;
--		elsif minUni = 9 then 
--			minUni <= 0;
--			minDez <= minDez + 1;
--		elsif minDez = 6 then
--			minDez <= 0;
--		elsif horaplus = '0' then
--			horauni <= horauni + 1;
--		elsif horaUni = 9 then
--		horaUni <= 0;
--		horaDez <= horaDez + 1;
--		elsif (horauni = 4) and (horaDez = 2) then 
--			horaUni <= 0;
--			HoraDez <= 0;
--end if;
--end if;
--end process;
-- Mesmo conceito do contador de JKs: a saida de um estagio e o clock do proximo (borda de descida).
-- saidaseg(5) fica em '1' de 32 a 59 segundos e cai na virada para 0 => tique do minuto.
-- fim_hora fica em '1' de 50 a 59 minutos e cai na virada para 00 => tique da hora.
-- No modo configuracao os botoes (ativos em '0') viram o clock.
clk_min  <= saidaseg(5) when configuracao = '0' else minplus;
fim_hora <= '1' when minDez = 5 else '0';
clk_hora <= fim_hora when configuracao = '0' else horaplus;

process(clk_min)
begin
	if falling_edge(clk_min) then
		if minUni = 9 then
			minUni <= 0;
			if minDez = 5 then
				minDez <= 0;
			else
				minDez <= minDez + 1;
			end if;
		else
			minUni <= minUni + 1;
		end if;
	end if;
end process;

process(clk_hora)
begin
	if falling_edge(clk_hora) then
		if (horaDez = 2) and (horaUni = 3) then
			horaUni <= 0;
			horaDez <= 0;
		elsif horaUni = 9 then
			horaUni <= 0;
			horaDez <= horaDez + 1;
		else
			horaUni <= horaUni + 1;
		end if;
	end if;
end process;



dig7seg <= saida;
configuracao <= ehkey(7);
minplus <= ehkey(8);
horaplus <= ehkey(9);


segundo: entity work.conta_1seg
port map (clk => clocK_50,frequencia => 1, pulso => seg(0));

khz: entity work.conta_1seg
port map (clk => clocK_50,frequencia => 400, pulso => seg(1));

-- contador para a variaçao do display 7seg

FLIP_FLOP0: entity work.Flip_Flop_JK							--OBS: O clock do flip flop é comandado pelo botão
port map(J => '1', K => '1', Clk => seg(1), Clr => '1',	Q => saida(0));
FLIP_FLOP1: entity work.Flip_Flop_JK
port map(J => '1', K => '1', Clk => saida(0),Clr => '1', Q => saida(1));

rst_segundos <= not (saidaseg(5) and saidaseg(4) and saidaseg(3) and saidaseg(2));
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

BCDminUni: entity work.int_7seg
port map (int => minuni, seg => minBCDUni);
BCDminDez: entity work.int_7seg
port map (int => mindez, seg => minBCDDez);

BCDhorauni: entity work.int_7seg
port map (int => horauni, seg => horaBCDuni);
BCDhoradez: entity work.int_7seg
port map (int => horaDez, seg => horaBCDDez);



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
LED <= (others => '0');
end behaviorOfTest;

