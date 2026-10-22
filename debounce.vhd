--BIBLIOTECAS USADAS PARA REALIZAÇÃO DO PROGRAMA
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Debounce de botao: a saida so muda depois que a entrada ficar estavel
-- durante "ciclos" periodos de clk (padrao: 500000 x 20 ns = 10 ms a 50 MHz).
-- apertou = pulso de 1 ciclo de clk na transicao 1 -> 0 ja filtrada.
entity debounce is
	generic
	(
	ciclos : integer := 500000
	);
	port
	(
	clk     : in  std_logic;
	entrada : in  std_logic; -- botao cru (com bouncing)
	saida   : out std_logic; -- botao filtrado
	apertou : out std_logic  -- pulso na borda 1 -> 0
	);
end debounce;

architecture behaviorOfTest of debounce is
signal sinc: std_logic_vector(1 downto 0) := "11"; -- sincronizador (evita metaestabilidade)
signal estado, estado_ant: std_logic := '1';
begin

process(clk)
variable count: integer range 0 to ciclos;
begin
	if rising_edge(clk) then
		sinc <= sinc(0) & entrada;
		estado_ant <= estado;
		if sinc(1) = estado then   -- entrada igual ao estado filtrado: zera a contagem
			count := 0;
		elsif count = ciclos then  -- ficou estavel tempo suficiente: aceita o novo valor
			count := 0;
			estado <= sinc(1);
		else
			count := count + 1;
		end if;
	end if;
end process;

saida   <= estado;
apertou <= estado_ant and not estado;

end behaviorOfTest;
