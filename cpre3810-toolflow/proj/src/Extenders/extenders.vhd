-- Isaiah Pridie
-- CprE 3810 Lab2 Part 6.c
-- Start Date: 2.22.2026    7:14 PM

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity extenders is
    port(i_imm  : in std_logic_vector(11 downto 0);    -- input 12 bit immediate value
         i_ZoS  : in std_logic;                        -- Bit to choose between 
         o_out  : out std_logic_vector(31 downto 0));   -- Output (32-bit) vector
end extenders;

architecture dataflow of extenders is
begin

    with i_ZoS select
    o_out   <=  x"FFFFF" & i_imm(11 downto 0) when '1',
                x"00000" & i_imm(11 downto 0) when '0';
                -- No others. Only two options for this mux (1, 0)

end dataflow;
