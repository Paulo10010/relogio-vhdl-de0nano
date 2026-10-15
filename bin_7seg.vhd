library ieee;
use ieee.std_logic_1164.all;

entity bin_7seg is
    port (
        bin : in  std_logic_vector(3 downto 0);   -- digito BCD (0 a 9)
        seg : out std_logic_vector(6 downto 0)    -- "g f e d c b a"
    );
end entity bin_7seg;

architecture rtl of bin_7seg is
begin

    with bin select
        seg <= "0111111" when "0000",   -- 0  : a b c d e f
               "0000110" when "0001",   -- 1  : b c
               "1011011" when "0010",   -- 2  : a b d e g
               "1001111" when "0011",   -- 3  : a b c d g
               "1100110" when "0100",   -- 4  : b c f g
               "1101101" when "0101",   -- 5  : a c d f g
               "1111101" when "0110",   -- 6  : a c d e f g
               "0000111" when "0111",   -- 7  : a b c
               "1111111" when "1000",   -- 8  : todos
               "1101111" when "1001",   -- 9  : a b c d f g
               "0000000" when others;   -- apagado (valor invalido)

end architecture rtl;
