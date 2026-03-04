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

    CONCATENATION: process(i_imm, i_ZoS)
    begin
        -- Using if statments instead of a mux because me thinks it is easier/faster to code
        -- Extends by concatenating a string of bits to the MS side of the input vector (i_imm)
        if i_ZoS = '1' then             -- If Sign extending
            if i_imm(11) = '1' then     -- Sign extend with 1s
                o_out   <= x"FFFFF" & i_imm(11 downto 0);   -- assign all '1's at top. xFFFFF = All ones for 20 bits
            else 
                o_out   <= x"00000" & i_imm(11 downto 0);   -- assign all '0's at top. x00000 = All zeros for 20 bits
            end if;
        else            -- if Zero extending
            o_out   <= x"00000" & i_imm(11 downto 0);       -- Zero exntending with 20 bits of Zero at beginning
        end if;

    end process;
end architecture;