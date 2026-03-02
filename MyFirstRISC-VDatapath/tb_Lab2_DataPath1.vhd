-- Isaiah Pridie
-- CprE 3810 Lab2 Part 4(d)
-- Start Date: 2.18.2026,   5:08 PM

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_Lab2_DataPath1 is
    generic(gCLK_HPER   : time := 50 ns); 
end entity;


architecture Lab2_DataPath1 of tb_Lab2_DataPath1 is
    -- Calculate the clock period as twice the half-period
    constant cCLK_PER  : time := gCLK_HPER * 2;

    -- Declare signals here:
    signal nAddSub  : std_logic;     -- Control/Select bit for AdderSub
    signal is_CLK    : std_logic;     -- Clock Signal for register
    signal is_RST    : std_logic;     -- RESET bit
    signal is_rs1    : std_logic_vector(4 downto 0);   -- 5 bit bus    -- [19:15]
    signal is_rs2    : std_logic_vector(4 downto 0);   -- 5 bit bus    -- [24:20]
    signal is_rd     : std_logic_vector(4 downto 0);   -- 5 but bus    -- [11:7]
    signal is_imm    : std_logic_vector(31 downto 0);    
    signal is_ALUSrc : std_logic;       -- Choose between imm and rs2
    signal regWrite  : std_logic;     -- Decoder EN bit

    signal o_rs1     : std_logic_vector(31 downto 0);    -- Result of RS1 input
    signal o_rs2     : std_logic_vector(31 downto 0);    -- Result of RS2 input
    
    signal i_DATA    : std_logic_vector(31 downto 0);  -- 32 bit bus   -- Register Data Input

    component Lab2_DataPath1 is
        port(nAddSub    : in std_logic;     -- Control bit for Adder/Subtractor
             i_CLK      : in std_logic;     -- Clock (obviously)
             i_RST      : in std_logic;     -- Reset (obivously)
             i_rs1      : in std_logic_vector(4 downto 0);
             i_rs2      : in std_logic_vector(4 downto 0);
             i_rd       : in std_logic_vector(4 downto 0);
             i_imm      : in std_logic_vector(31 downto 0); -- Need for immediate value
             i_ALUSrc   : in std_logic;     -- Controls using rs2 OR imm
             regWrite   : in std_logic;     -- i_dEN : Decoder Enable
             
             o_rs1      : out std_logic_vector(31 downto 0);
             o_rs2      : out std_logic_vector(31 downto 0);
             o_alu      : out std_logic_vector(31 downto 0)
             );
    end component;

    begin
    DUT: Lab2_DataPath1
        -- Left is component => Right is signal
        port map(nAddSub   => nAddSub,
                 i_CLK     => is_CLK,   
                 i_RST     => is_RST,       
                 i_rs1     => is_rs1,       -- i_RS1 goes to entity i_rs1
                 i_rs2     => is_rs2,       -- i_RS2 goes to entity i_rs2
                 i_rd      => is_rd,        -- i_rd goes to entity i_rd
                 i_imm     => is_imm,   
                 i_ALUSrc  => is_ALUSrc,    -- Choosing between imm and rs2
                 regWrite  => regWrite,     -- Decoder Enable
    
                o_rs1      => o_rs1,
                o_rs2      => o_rs2,
                o_alu      => i_DATA    
                 );
    -- This process sets up the clock:
    P_CLK: process
    begin
        is_CLK <= '0';
        wait for gCLK_HPER;
        is_CLK <= '1';
        wait for gCLK_HPER;
    end process;

    -- Everything else:
    TEST_CASES: process 
    begin

    ------------------------------------
    ------ Test Case 1.0 ---------------
    ------------------------------------
        -- Check register x0 value before doing anything
    nAddSub     <= '0';     -- adding
    is_RST      <= '0';
    regWrite    <= '0';     -- just looking at registers - don't write anything
    is_rs1      <= "00000";     -- Select reg_x0 to view
    is_rs2      <= "00000";     -- Select reg_x0 to view
    is_rd       <= "00000";     -- Save result* to x0
    is_ALUSrc   <=  '0';        -- Use both registers
    wait for cCLK_PER;  
    -- Expected:    
        -- o_rs1 = 0    |   o_rs2 = 0        

    ------------------------------------
    ------ Test Case 1.1 ---------------
        -- Move rd to x2
    regWrite    <= '1'; 
    is_rd       <= "00010";
    wait for cCLK_PER;
    regWrite    <= '0'; 
    -- Expected:
        -- x2 will show a value of 0x00000000

    ------------------------------------
    ------ Test Case 1.2 ---------------
        -- move rs2 to a register that has not been reset [x8]
    regWrite    <= '1'; 
    is_rs2      <= "01000"; 
    wait for cCLK_PER;
    regWrite    <= '0'; 
    -- Expected:
        -- output (i_DATA) may be unknown

    ------------------------------------
    ------ Test Case 1.3 ---------------
        -- Try writing to x0 a couple times
    is_rd       <= "00000";
    is_rs1      <= "00000";
    is_ALUSrc   <=  '1';        -- Use rs1 and imm
    is_imm      <= x"00110011"; -- some arbitrary unsigned value
    regWrite    <= '1';

    for i in 0 to 2 loop
        wait for cCLK_PER;
    end loop;
    regWrite    <= '0';
    is_ALUSrc   <=  '0';        -- reset to some default for now      
    -- Expected:
        -- o_rs1 to stay 0, i_DATA to stay 0x00110011


    ------------------------------------------
    ------ Test Case 2.0 ---------------------
    ------------------------------------------
        -- Set immediate to some value. [0x12345678]
        -- Add imm to x0
        -- Save to some register. [x6]
    nAddSub     <= '0';
    is_RST      <= '0';
    is_rs1      <= "00000";
    is_imm      <= x"12345678"; 
    is_ALUSrc   <=  '1';        -- Use Immediate. NOT register

    regWrite    <= '1';
    is_rd       <= "00110";     -- Destination Regster = register x6
    wait for cCLK_PER;  

    regWrite    <= '0';
    is_ALUSrc   <= '0';
    
    -- Expected:
        -- Add 0x12345678 to 0. Save that value in register x6

    ------------------------------------
    ------ Test Case 2.1 ---------------
        -- set rs1 to previous rd [x6]. 
        -- Subtract x5678 from rs1
        -- save to x7
    nAddSub     <= '1';
    is_rs1      <= "00110";
    is_imm      <= x"00005678";
    is_ALUSrc   <=  '1';        -- Use Immediate. NOT register

    regWrite    <= '1';
    is_rd       <= "00111";     -- Destination Regster = register x7
    wait for cCLK_PER;  

    regWrite    <= '0';
    is_ALUSrc   <= '0';
    -- Expected:
        -- output [i_DATA] sould be 0x12340000
    

    ------------------------------------
    ------ RESET ALL REGISTERS ---------
    ------------------------------------
    is_RST      <= '1';
    wait for cCLK_PER;  
    is_RST      <= '0';
    wait for cCLK_PER;  -- MAKE SURE is_RST is 0 before doing anything else


    ------------------------------------------
    ------ Test Case 3.0 ---------------------
    ------------------------------------------
        -- Zero register x6
        -- Reproduce a for-loop scenario: continuously incrementing by 1
        -- Then take it back down to 0 incrementing by -1 
    nAddSub     <= '0';
    is_RST      <= '0';
    is_rs1      <= "00000";
    is_rs2      <= "00000";
    is_rd       <= "00110";
    is_ALUSrc   <=  '0';        -- Use BOTH registers from rs1 and rs2

    regWrite    <= '1';
    is_rd       <= "00110";     -- Destination Regster = register x6    
    wait for cCLK_PER;  
    
    -- Done zeroing register x6
    
    is_rs1      <= "00110";    -- set rs1 to x6    
    is_ALUSrc   <=  '1';        -- Use rs1 and immediate
    is_imm      <= x"00000001";
    -- Done setting up x6++;
    
    for i in 0 to 10 loop
        wait for cCLK_PER;  
    end loop;

    nAddSub     <= '1';

    for i in 0 to 20 loop
        wait for cCLK_PER;  
    end loop;
    regWrite    <= '0';
    is_ALUSrc   <=  '0';        -- Use rs1 and rs2 (set back some default for now)
    -- Expected:
        -- i_DATA increments from 0 to 10 by 1 each clock cycle




    -- Wait a few clock cycles so I CLEARLY know where I am in the waveforms
    wait until rising_edge(is_CLK); 
    wait until rising_edge(is_CLK); 
    wait until rising_edge(is_CLK); 


    ------------------------------------
    ------ Test Case 4 -----------------
    ------------------------------------
        -- ACTUAL tests described by lab document
      -- ADDi xN, zero, N       # Place "N" in xN

    -- Reset the registers
    is_RST          <= '1';
    wait until rising_edge(is_CLK); 
    is_RST          <= '0';
    wait until rising_edge(is_CLK);    

    -- Set up signals for for loop 
    is_rd           <= "00001"; -- x1
    is_imm          <= x"00000001"; -- = 0x1
    regWrite     <= '1';     -- enable decoder enable
    is_ALUSrc        <= '1';     -- use immediate
    nAddSub         <= '0';     -- perform addition only
    is_rs1          <= "00000"; -- use x0 for rs1

    for k in 0 to 9 loop
        wait until rising_edge(is_CLK); 
        is_rd       <= std_logic_vector(unsigned(is_rd)    + 1); -- update variables
        is_imm      <= std_logic_vector(unsigned(is_imm)   + 1); -- update variables
    end loop;

      ------------------------------------
      -- ADDi x11,  x1,  x2     # x11 = x1 + x2
    is_ALUSrc        <= '0';     -- use rs2
    is_rd       <= "01011";     -- x11
    is_rs1      <= "00001";     -- x1
    is_rs2      <= "00010";     -- x2
    wait until rising_edge(is_CLK); 

      ------------------------------------
      -- ADD / SUB xN, x(N-1), xS

    is_rd       <= "01100";     -- x12
    is_rs1      <= "01011";     -- x11
    is_rs2      <= "00011";     -- x3

    for k in 0 to 7 loop
        if (k mod 2) = 0 then   -- PERFORM SUB
            nAddSub     <= '1';
        else                    -- PERFORM ADD
            nAddSub     <= '0';
        end if;
        
        wait until rising_edge(is_CLK);     

        is_rd   <= std_logic_vector(unsigned(is_rd)  + 1);  -- update Dest. Reg. first for obv reason
        is_rs1  <= std_logic_vector(unsigned(is_rs1) + 1);
        is_rs2  <= std_logic_vector(unsigned(is_rs2) + 1);
    end loop;

      ------------------------------------
      -- ADDi x20,  zero,   -35     # Place "-35" in x20
    is_rd       <= "10100";       -- x20
    is_rs1      <= "00000";       -- x0
    is_imm      <= x"00000023";   -- 35 in hex
    is_ALUSrc   <= '1';           -- use IMM  
    nAddSub     <= '1';           -- Subtract that shit twin!
    wait until rising_edge(is_CLK); 

      ------------------------------------
      -- ADD x21,  x19,  x20
    is_rd       <= "10101";     -- x21
    is_rs1      <= "10011";     -- x19
    is_rs2      <= "10100";     -- x20
    is_ALUSrc   <= '0';         -- Use both RS1 AND RS2, not imm
    nAddSub     <= '0';         -- Don't subtract twin
    wait until rising_edge(is_CLK); 
       
    regWrite    <= '0';         -- Done with test cases. Turn off register write enable. (best practice...? Probs.)

        wait;
    end process;
end architecture;
