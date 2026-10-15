library ieee;
use ieee.std_logic_1164.all;

entity int_7seg is
    port (
        int : in  integer range 0 to 9;   -- digito BCD (0 a 9)
        seg : out std_logic_vector(6 downto 0)    -- "g f e d c b a"
    );
end entity int_7seg;

architecture rtl of int_7seg is
begin

    with int select
        seg <= "0111111" when 0,   -- 0  : a b c d e f
               "0000110" when 1,   -- 1  : b c
               "1011011" when 2,   -- 2  : a b d e g
               "1001111" when 3,   -- 3  : a b c d g
               "1100110" when 4,   -- 4  : b c f g
               "1101101" when 5,   -- 5  : a c d f g
               "1111101" when 6,   -- 6  : a c d e f g
               "0000111" when 7,   -- 7  : a b c
               "1111111" when 8,   -- 8  : todos
               "1101111" when 9,   -- 9  : a b c d f g
               "0000000" when others;   -- apagado (valor invalido)

end architecture rtl;
