-- Isaiah Pridie
-- CprE 381 Project01 Fetcher component thing TEST_BENCH
-- Start Date: 3.3.2026,    1:54 PM


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_proj1_fetch is
    generic(gCLK_HPER   : time := 10 ns);   -- Changed the time from 50 ns to 10 ns (can be adjusted more)
end tb_proj1_fetch;

architecture structural of tb_proj1_fetch is
    
    -- Declare signals/constants    (These will show up on QuestaSim)
    constant cCLK_PER  : time := gCLK_HPER * 2; -- Calculate the clock period as twice the half-period
    
    signal is_CLK       : std_logic;    
    signal is_RST_PC    : std_logic;
    signal is_imm       : std_logic_vector(31 downto 0);    -- Imm AFTER sign extending
    signal cs_PC_add     : std_logic;            -- Control bit for choosign between "+4" or "+Imm"
    signal os_PC_val     : std_logic_vector(31 downto 0);    -- Displays registers contents

    component proj1_fetch is
        port(i_CLK      : in std_logic;
             i_RST_PC   : in std_logic;     -- Need different reset* (this one); We need to reset register to 0x0040.0000 not 0x0000.0000
             i_imm      : in std_logic_vector(31 downto 0);     -- imm AFTER SIGN-EXTENDING AND MUXING
             c_PC_add   : in std_logic;                         -- Control bit for choosing between "+4" and "+imm"
             o_PC       : out std_logic_vector(31 downto 0) );  -- Output from PC register to Instruction memory
    end component;

    begin
    DUT: tb_proj1_fetch
        -- Component Port => Signal
        port map(i_CLK      => is_CLK,
                 i_RST_PC   => is_RST_PC,
                 i_imm      => is_imm,
                 c_PC_add   => cs_PC_add,
                 o_PC       => os_PC_val);

    P_CLK: process
    begin
        is_CLK <= '0';
        wait for gCLK_HPER;
        is_CLK <= '1';
        wait for gCLK_HPER;
    end process;

    TEST_CASES: process

        ----------------------------
        ------ TEST CASE 1.0: ------
          -- Reset PC register
        is_RST_PC   <= '1'; -- Turn reset signal ON
        cs_PC_add   <= '0'; -- Set to a default value - Prevent unexepected behavior when RST goes low
        i_imm       <= x"00000000";     -- Same reason as above
        wait until rising_edge(is_clk);

        -- Turn reset signal OFF and wait for it to be off before trying anything else.
        is_RST_PC   <= '0'
        wait until rising_edge(is_clk);
        -- Expected: o_PC = 0x0040.0000


        ------ TEST CASE 1.1: ------
          -- Set PC Register to 0
        is_RST_PC   <= '0';
        c_PC_add    <= '1'  -- Set to loading from immediate
        i_imm       <= x"00000000"; -- Set to all 0
        wait until rising_edge(is_clk);
        -- Expected: o_PC = 0x0000.0000

        
        ------ TEST CASE 1.2: ------
          -- Set PC register to all 1
        is_RST_PC   <= '0';
        c_PC_add    <= '1'  -- Set to loading from immediate
        i_imm       <= x"FFFFFFFF"; -- Set to all 0
        wait until rising_edge(is_clk);
        -- Expected: o_PC = 0xFFFF.FFFF


        ------ TEST CASE 1.3: ------
          -- Add 1 to PC register of all F's
        is_RST_PC   <= '0';
        c_PC_add    <= '1'  -- Set to loading from immediate
        i_imm       <= x"00000001"; -- Set to 0x1
        wait until rising_edge(is_clk);
        -- Expected: o_PC = 0x0000.0000


        ------ TEST CASE 1.4: ------
          -- Reset PC register with is_RST_PC
        is_RST_PC   <= '1';
        c_PC_add    <= '0'          -- Set to default of "+ 4"
        i_imm       <= x"00000000"; -- Set to default
        wait until rising_edge(is_clk);
        -- Expected: o_PC = 0x0040.0000



        ----------------------------
        ------ TEST CASE 2.0: ------
          -- Test +4 and +imm adders with loop
          -- Should be starting from a reset PC register
        i_imm       <= x"00000100"; -- Initialize the i_imm vector with a value
        
        for k in 0 to 10 loop

            if (k mod 2) = 0 then   -- if even, add 4
                c_PC_add    <= '0';
            else 
                i_imm       ;   -- add 0x100 to the PC register every odd iteration

            end if;

            wait until rising_edge(is_clk);
        end loop;
        -- Expected: 
            --
            --
            --
            --
        ----------------------------
        ------ TEST CASE 3.0: ------



    end process;
end architecture;
