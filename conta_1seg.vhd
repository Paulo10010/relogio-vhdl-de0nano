library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity conta_1seg is
    Port (	clk   : in  std_logic;     -- input
				frequencia: in integer;		-- Variavel que seleciona a frequencia
				pulso : out std_logic      -- output
	  );
end conta_1seg;

architecture Behavioral of conta_1seg is
signal auxiliar: std_logic;
begin

process(clk) -- Divisor do sinal de clock da placa(50Mhz)
variable count: integer range 0 to 25000000;
begin
	if rising_edge(clk) then
		count:=count+1;
		if count=(25000000/frequencia) then
			count:=0;
			auxiliar<= not auxiliar;
		end if;
	end if;
end process;

pulso<=auxiliar;

end Behavioral;