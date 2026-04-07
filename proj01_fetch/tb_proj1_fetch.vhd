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
    signal is_alu       : std_logic_vector(31 downto 0);    -- jalr target address from ALU
    signal cs_PC_sel    : std_logic_vector(1 downto 0);     -- 00 = +4, 01 = +imm, 10 = jalr target
    signal os_PC_val    : std_logic_vector(31 downto 0);    -- Displays registers contents
    signal os_PC4_val   : std_logic_vector(31 downto 0);    -- Displays PC + 4 contents
    -- signal is_alu       : std_logic_vector(31 downto 0);    -- jalr target address from ALU
    -- signal os_PC4_val   : std_logic_vector(31 downto 0);    -- Displays "PC + 4" contents

    component proj1_fetch is
        port(i_CLK      : in std_logic;
             i_RST_PC   : in std_logic;     -- Need different reset* (this one); We need to reset register to 0x0040.0000 not 0x0000.0000
             i_imm      : in std_logic_vector(31 downto 0);     -- imm AFTER SIGN-EXTENDING AND MUXING
             i_alu      : in std_logic_vector(31 downto 0); -- jal target address from ALU (for jalr)
             c_PC_sel   : in std_logic_vector(1 downto 0); -- Control bits for choosing between "+4", "+imm", and "jalr target address" 00 = +4, 01 = +imm, 10 = jalr target address
             o_PC       : out std_logic_vector(31 downto 0);  -- Output from PC register to Instruction memory
             o_PC4      : out std_logic_vector(31 downto 0) );  -- Output of "PC + 4" for use in jal instructions (to be stored in rd)
    end component;

    begin
    DUT: proj1_fetch
        -- Component Port => Signal
        port map(i_CLK      => is_CLK,
                 i_RST_PC   => is_RST_PC,
                 i_imm      => is_imm,
                 i_alu      => is_alu,
                 c_PC_sel   => cs_PC_sel,
                 o_PC       => os_PC_val,
                 o_PC4      => os_PC4_val);

    P_CLK: process
    begin
        is_CLK <= '0';
        wait for gCLK_HPER;
        is_CLK <= '1';
        wait for gCLK_HPER;
    end process;

    TEST_CASES: process
    begin

        ----------------------------
        ------ TEST CASE 1.0: ------
          -- Reset PC register
        is_RST_PC   <= '1'; -- Turn reset signal ON
        cs_PC_sel   <= "00"; -- Set to a default value - Prevent unexepected behavior when RST goes low
        is_imm      <= x"00000000";     -- Same reason as above
        is_alu      <= x"00000000";     -- Same reason as above
        wait until rising_edge(is_clk);
        -- Expected: o_PC = 0x0040.0000 | o_PC4 = 0x0040.0004

        
        ------ TEST CASE 1.1: ------
          -- Set PC register to all 1
        is_RST_PC   <= '0';   -- Make sure reset signal goes low
        cs_PC_sel   <= "01";  -- Set to adding immediate
        -- What + 0x0040.0000 = 0xFFFF.FFFF -> 0xFFBF.FFFF
        is_imm      <= x"FFBFFFFF"; -- Set to all 1
        is_alu      <= x"00000000"; -- Default value
        wait until rising_edge(is_clk);
        -- Expected: o_PC = 0xFFFF.FFFF | o_PC4 = 0x0000.0003


        ------ TEST CASE 1.2: ------
          -- Add 1 to PC register of all F's
        is_RST_PC   <= '0';
        cs_PC_sel   <= "01";  -- Set to adding immediate
        is_imm      <= x"00000001"; -- Set to 0x1
        is_alu      <= x"00000000"; -- Default value
        wait until rising_edge(is_clk);
        -- Expected: o_PC = 0x0000.0000 | o_PC4 = 0x0000.0004


        ------ TEST CASE 1.3: ------
          -- Reset PC register with is_RST_PC
        is_RST_PC   <= '1';
        cs_PC_sel   <= "00";         -- Set to default of "+ 4"
        is_imm      <= x"00000000"; -- Set to default
        is_alu      <= x"00000000"; -- Set to default
        wait until rising_edge(is_clk);
        -- Expected: o_PC = 0x0040.0000 | o_PC4 = 0x0040.0004


        ----------------------------
        ------ TEST CASE 2.0: ------
          -- Test +4 and +imm adders with loop
          -- Should be starting from a reset PC register
        is_RST_PC   <= '0';         -- Turn Reset OFF
        is_imm      <= x"00001000"; -- Initialize the i_imm
        is_alu      <= x"00000000"; -- Default value
        
        for k in 0 to 15 loop       -- Loop 16 times

            if (k mod 2) = 0 then   -- if even, add 4
                cs_PC_sel   <= "00";
            else                    -- else, add is_imm
                cs_PC_sel   <= "01";
            end if;

            wait until rising_edge(is_clk);
        end loop;
        -- Expected: 
            -- (0)  o_PC = 0x0040.0004   | (1)   o_PC = 0x0040.1004
            -- (2)  o_PC = 0x0040.1008   | (3)   o_PC = 0x0040.2008
            -- (4)  o_PC = 0x0040.200C   | (5)   o_PC = 0x0040.300C
            -- (6)  o_PC = 0x0040.3010   | (7)   o_PC = 0x0040.4010
            -- (8)  o_PC = 0x0040.4014   | (9)   o_PC = 0x0040.5014
            -- (10) o_PC = 0x0040.5018   | (11)  o_PC = 0x0040.6018
            -- (12) o_PC = 0x0040.601C   | (13)  o_PC = 0x0040.701C
            -- (14) o_PC = 0x0040.7020   | (15)  o_PC = 0x0040.8020
            -- Final o_PC4 = 0x0040.8024


        ----------------------------
        ------ TEST CASE 3.0: ------
          -- Reset PC register before jalr tests
        is_RST_PC   <= '1';         -- Reset signal ON
        cs_PC_sel   <= "00";       -- Default value
        is_imm      <= x"00000000"; -- Default value
        is_alu      <= x"00000000"; -- Default value
        wait until rising_edge(is_clk);
        -- Expected: o_PC = 0x0040.0000 | o_PC4 = 0x0040.0004


        ------ TEST CASE 3.1: ------
          -- Test jalr target address from ALU
        is_RST_PC   <= '0';
        cs_PC_sel   <= "10";       -- Select jalr target address
        is_imm      <= x"11111111"; -- Should be ignored
        is_alu      <= x"12345678"; -- Set jalr target address
        wait until rising_edge(is_clk);
        -- Expected: o_PC = 0x1234.5678 | o_PC4 = 0x1234.567C


        ------ TEST CASE 3.2: ------
          -- Add 4 after jalr target address
        is_RST_PC   <= '0';
        cs_PC_sel   <= "00";       -- Select "+4"
        is_imm      <= x"00000000"; -- Default value
        is_alu      <= x"AAAAAAAA"; -- Should be ignored
        wait until rising_edge(is_clk);
        -- Expected: o_PC = 0x1234.567C | o_PC4 = 0x1234.5680


        ------ TEST CASE 3.3: ------
          -- Test another jalr target address from ALU
        is_RST_PC   <= '0';
        cs_PC_sel   <= "10";       -- Select jalr target address
        is_imm      <= x"FFFFFFFF"; -- Should be ignored
        is_alu      <= x"00400120"; -- Set jalr target address
        wait until rising_edge(is_clk);
        -- Expected: o_PC = 0x0040.0120 | o_PC4 = 0x0040.0124


        ----------------------------
        ------ TEST CASE 4.0: ------
          -- Reset PC register before negative immediate tests
        is_RST_PC   <= '1';
        cs_PC_sel   <= "00";
        is_imm      <= x"00000000";
        is_alu      <= x"00000000";
        wait until rising_edge(is_clk);
        -- Expected: o_PC = 0x0040.0000 | o_PC4 = 0x0040.0004


        ------ TEST CASE 4.1: ------
          -- Add positive immediate to PC register
        is_RST_PC   <= '0';
        cs_PC_sel   <= "01";       -- Select "+imm"
        is_imm      <= x"00000020"; -- Set positive immediate
        is_alu      <= x"00000000"; -- Default value
        wait until rising_edge(is_clk);
        -- Expected: o_PC = 0x0040.0020 | o_PC4 = 0x0040.0024


        ------ TEST CASE 4.2: ------
          -- Add negative immediate to PC register
        is_RST_PC   <= '0';
        cs_PC_sel   <= "01";       -- Select "+imm"
        is_imm      <= x"FFFFFFF0"; -- Set to -16
        is_alu      <= x"00000000"; -- Default value
        wait until rising_edge(is_clk);
        -- Expected: o_PC = 0x0040.0010 | o_PC4 = 0x0040.0014


        ------ TEST CASE 4.3: ------
          -- Add zero immediate to PC register
        is_RST_PC   <= '0';
        cs_PC_sel   <= "01";       -- Select "+imm"
        is_imm      <= x"00000000"; -- Set to 0
        is_alu      <= x"00000000"; -- Default value
        wait until rising_edge(is_clk);
        -- Expected: o_PC = 0x0040.0010 | o_PC4 = 0x0040.0014


        ----------------------------
        ------ TEST CASE 5.0: ------
          -- Reset PC register before testing c_PC_sel = "11"
        is_RST_PC   <= '1';
        cs_PC_sel   <= "00";
        is_imm      <= x"00000000";
        is_alu      <= x"00000000";
        wait until rising_edge(is_clk);
        -- Expected: o_PC = 0x0040.0000 | o_PC4 = 0x0040.0004


        ------ TEST CASE 5.1: ------
          -- Test c_PC_sel = "11"
        is_RST_PC   <= '0';
        cs_PC_sel   <= "11";       -- Current mux structure should still select ALU when bit(1) = 1
        is_imm      <= x"00001000"; -- Should be ignored
        is_alu      <= x"0BADB002"; -- Expected selected value
        wait until rising_edge(is_clk);
        -- Expected: o_PC = 0x0BAD.B002 | o_PC4 = 0x0BAD.B006


        ------ TEST CASE 5.2: ------
          -- Add 4 after c_PC_sel = "11"
        is_RST_PC   <= '0';
        cs_PC_sel   <= "00";
        is_imm      <= x"00000000";
        is_alu      <= x"FFFFFFFF"; -- Should be ignored
        wait until rising_edge(is_clk);
        -- Expected: o_PC = 0x0BAD.B006 | o_PC4 = 0x0BAD.B00A


        ----------------------------
        ------ TEST CASE 6.0: ------
          -- Reset should override all other inputs
        is_RST_PC   <= '1';
        cs_PC_sel   <= "10";       -- Should be ignored because reset overrides everything
        is_imm      <= x"7FFFFFFF"; -- Should be ignored
        is_alu      <= x"FFFFFFFF"; -- Should be ignored
        wait until rising_edge(is_clk);
        -- Expected: o_PC = 0x0040.0000 | o_PC4 = 0x0040.0004


        ----------------------------
        ------ TEST CASE 7.0: ------
          -- Reset PC register one last time
        is_RST_PC   <= '1';         -- Reset signal ON
        cs_PC_sel   <= "00";       -- Default value
        is_imm      <= x"00000000"; -- Default value
        is_alu      <= x"00000000"; -- Default value
        wait until rising_edge(is_clk);
        -- Exepcted: o_PC = 0x0040.0000 | o_PC4 = 0x0040.0004
        
        wait;
    end process;
end architecture;
