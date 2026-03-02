-- Isaiah Pridie
-- CprE 3810 Lab2 Part 7.c
-- Start Date: 2.23.2026,   4:41 PM

-- mem load -infile dmem.hex -format hex /tb_MySecondDataPath/DUT/INST_MEMORY/ram

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity tb_MySecondDataPath is
    generic(gCLK_HPER   : time := 50 ns);
end entity;


architecture MySecondDataPath of tb_MySecondDataPath is
    -- Calculate the clock period as twice the half-period
    constant cCLK_PER  : time := gCLK_HPER * 2;

    -- Declare signals/constants
    signal is_CLK       : std_logic; 
    signal is_RST       : std_logic;
    signal is_rs1       : std_logic_vector(4  downto 0);     -- Drives rs1
    signal is_rs2       : std_logic_vector(4  downto 0);     -- Drives rs2
    signal is_rd        : std_logic_vector(4  downto 0);     -- Drives destination register
    signal nAddSub      : std_logic;     -- Controlls adding(0) or subtracting(1)
    signal is_Imm       : std_logic_vector(11 downto 0);     -- Holds imm from input
    signal is_ext_Ctrl  : std_logic;     -- Bit to control sign(1) vs zero(0) extending immediate input
    signal is_ALUSrc    : std_logic;     -- Drives choosing betweenr rs2(0) and imm(1)
    signal is_mem_o_alu : std_logic;     -- Select line to choose between MEM(1) or ALU(0) output to return to registers
    signal is_regWrite  : std_logic;     -- Controls decoder EN to select dest register
    signal is_memWE     : std_logic;     -- Write Enable for memory
    
    
    signal os_Data      : std_logic_vector(31 downto 0);    -- input Data to move to registers
    signal os_rs1       : std_logic_vector(31 downto 0);    -- Shows output of rs1 register contents
    signal os_rs2       : std_logic_vector(31 downto 0);    -- Shows output of rs2 register contents
    signal os_alu       : std_logic_vector(31 downto 0);    -- Shows output of addder
    signal os_memQ      : std_logic_vector(31 downto 0);    -- Shows memory output (q)

    component MySecondDataPath is
    port(i_CLK      : in std_logic;     -- Obviously Clock Signal
         i_RST      : in std_logic;     -- Obviously the Reset Signal
         i_rs1      : in std_logic_vector(4  downto 0);     -- Drives rs1
         i_rs2      : in std_logic_vector(4  downto 0);     -- Drives rs2
         i_rd       : in std_logic_vector(4  downto 0);     -- Drives destination register
         nAddSub    : in std_logic;     -- Controlls adding or subtracting
         i_SecImm   : in std_logic_vector(11 downto 0);     -- Holds imm from input
         ext_Ctrl   : in std_logic;     -- Bit to control sign vs zero extending immediate input
         ALUSrc     : in std_logic;     -- Drives choosing betweenr rs2 and imm
         mem_o_alu  : in std_logic;     -- Select line to choose between memory or alue output to return to registers
         regWrite   : in std_logic;     -- Controls decoder EN to select dest register
         i_memWE    : in std_logic;     -- Write Enable for memory
         
         o_Data     : out std_logic_vector(31 downto 0);     -- input Data to move to registers
         o_rs1      : out std_logic_vector(31 downto 0);    -- Shows output of rs1 register contents
         o_rs2      : out std_logic_vector(31 downto 0);    -- Shows output of rs2 register contents
         o_alu      : out std_logic_vector(31 downto 0);    -- Shows output of addder
         o_memQ     : out std_logic_vector(31 downto 0));    -- Shows memory output (q)
    end component;



    begin
    DUT: MySecondDataPath
        -- Left is component => Right is signal
        port map(i_CLK      => is_CLK,
                 i_RST      => is_RST,
                 i_rs1      => is_rs1,
                 i_rs2      => is_rs2,
                 i_rd       => is_rd,
                 nAddSub    => nAddSub,
                 i_SecImm   => is_Imm,
                 ext_Ctrl   => is_ext_Ctrl,
                 ALUSrc     => is_ALUSrc,
                 mem_o_alu  => is_mem_o_alu,
                 regWrite   => is_regWrite,
                 i_memWE    => is_memWE,
                 
                 o_Data     => os_Data,
                 o_rs1      => os_rs1,
                 o_rs2      => os_rs2,
                 o_alu      => os_alu,
                 o_memQ     => os_memQ);

    -- This process sets the clock value (low for gCLK_HPER, then high
    -- for gCLK_HPER). Absent a "wait" command, processes restart 
    -- at the beginning once they have reached the final statement.
    P_CLK: process
    begin
        is_CLK <= '0';
        wait for gCLK_HPER;
        is_CLK <= '1';
        wait for gCLK_HPER;
    end process;


    TEST_CASES: process
    begin

        -- "Load &A into x25, assuming x25 initially has 0x10010000 and a[0] is at 0x10010000"
        -- "Load &B into x26, assuming x26 initially has 0x10010000 and b[0] is at 0x10010100"

        -- So: . . . . . . . 
        --      a[0] is AT 0x10010000
        --      b[0] is AT 0x10010100
        -- But our immediate is 12 bits. Addresses are 10 bits.
            -- We know mem.vhd is word addressable from looking at the file:
                -- The data type is declared as a word and nothing else

            -- We cut off the lower 2 bits because mem.vhd is word addressable. 
            -- We should only be looking at the last few hex characters:

        -- A is at 0x000.
        -- B is at 0x100.
        
        -- Cut off the bottom two bits:
        -- A is at 0000 0000 00
        -- B is at 0001 0000 00

        -- Put back in hexadecimal
        -- A is at [00]00 0000 0000 = 0x000 = x25 (Address of A)
        -- B is at [00]00 0100 0000 = 0x040 = x26 (Address of B)

        -- Isaiah What are you doing. YOU ARE RETARDED
            -- (Think Woody screaming at Buzz Lightyear "YOU ARE A TOY", but "retarded" and at me instead).
        -- The computer already slices away the bottom two bits of the immediate value. 


        -- INITIALIZE, CLEAR, RESET EVERYTHING
        is_regWrite <= '0';         -- Don't write anything to the registers yet.
        is_memWE    <= '0';         -- Do Not Write anything to the memory yet.
        is_rd       <= "00000";     -- set destination register to x0  - Don't accidentally overwrite some random register
        is_rs1      <= "00000";     -- No surprises
        is_rs2      <= "00000";     -- No surprises
        nAddSub     <= '0';         -- Set to addition. No surprises
        is_Imm      <= x"000";      -- Again, no surprises
        is_ext_Ctrl <= '1';         -- For now, sign extend everything. Don't zero extend
        -- Don't touch is_Data; Only used to see waveform (idk why it's still an input. I forgot and don't want to fix it unless I have to).
        is_ALUSrc   <= '0';         -- For now default to use rs2, not imm
        is_mem_o_alu    <= '0';     -- For now use ALU

        is_RST      <= '1';         -- Reset registers
        wait until rising_edge(is_clk);
        is_RST      <= '0';         -- Turn reset back off
        wait until rising_edge(is_clk); -- wait for signal to go low before doing anything else
        -------- ---- -- - Done initializing - -- ---- --------


        ------ addi x25, zero, 0 ------
        is_rd       <= "11001";     -- x25
        is_rs1      <= "00000";     -- x0
        is_ALUSrc   <= '1';         -- Use immediate value
        is_Imm      <= x"000";      -- use 0 immediate
        is_mem_o_alu    <= '0';     -- Use ALU result
        is_regWrite <= '1';         -- Make sure we are writing to the registers
        is_memWE    <= '0';         -- memWE off
        wait until rising_edge(is_clk);


        ------ addi x26, x0, 0x100 ------
          -- Load x26 with 0x040 (0x100 turn into 0x040 after cutting off bottom two bits)
          -- Do this with the imm. 
        is_rd       <= "11010";     -- x26
        is_rs1      <= "00000";     -- x0
        is_ALUSrc   <= '1';         -- Use imm value
        is_Imm      <= x"100";      -- Set immediate to 0x100. This will turn into 0x040 from slicing away bottom 2 bits
        is_mem_o_alu    <= '0';     -- Load from ALU
        is_regWrite <= '1';         -- regWE on
        is_memWE    <= '0';         -- memWE off
        wait until rising_edge(is_clk);


        ------ lw   x1, 0(x25) ------
          -- Load word in x1 from A[0]
        is_rd       <= "00001";     -- x1
        is_rs1      <= "11001";     -- x25
        is_ALUSrc   <= '1';         -- Use imm Value (for addr offset)
        is_Imm      <= x"000";      -- Immediate of 0
        is_mem_o_alu  <= '1';       -- Load from Mem
        is_regWrite <= '1';         -- regWE on
        is_memWE    <= '0';         -- memWE off
        wait until rising_edge(is_clk);


        ------ lw   x2, 4(x25) ------
          -- Load word into x2 from A[4];
        is_rd       <= "00010";     -- x2
        is_rs1      <= "11001";     -- x25
        is_ALUSrc   <= '1';         -- Use imm Value (for addr offset)
        is_Imm      <= x"004";      -- 01 | 00
        is_mem_o_alu  <= '1';       -- Load from Mem
        is_regWrite <= '1';         -- regWE on
        is_memWE    <= '0';         -- memWE off
        wait until rising_edge(is_clk);   


        ------ add  x1, x1, x2 ------
          -- Add x1 + x2, store result in x1
        is_rd       <= "00001";     -- x1
        is_rs1      <= "00001";     -- x1
        is_rs2      <= "00010";     -- x2
        -- No Imm needed
        is_mem_o_alu    <= '0';       -- Load from ALU
        is_ALUSrc   <= '0';         -- Use registers only
        is_regWrite <= '1';         -- regWE on
        is_memWE    <= '0';         -- memWE off
        wait until rising_edge(is_clk);


        ------ sw   x1, 0(x26) ------
          -- Store contents of x1 at B[0]
        is_rd       <= "00000";     -- x0. Not needed. Here to be safe
        is_rs1      <= "11010";     -- &B = x26
        is_rs2      <= "00001";     -- x1
        is_Imm      <= x"000";      -- 0(x)
        -- is_mem_o_alue            -- doesn't matter
        is_ALUSrc   <= '1';         -- Use imm Value (for addr offset)
        is_regWrite <= '0';         -- regWE off
        is_memWE    <= '1';         -- memWE on
        wait until rising_edge(is_clk);
        wait until rising_edge(is_clk);     -- Test is we can see the result of write by next clock cycle


        ------ lw   x2, 8(x25) ------
        is_rd       <= "00010";     -- x2
        is_rs1      <= "11001";     -- x25
        is_ALUSrc   <= '1';         -- Use imm Value (for addr offset)
        is_Imm      <= x"008";      -- 10 | 00
        is_mem_o_alu  <= '1';       -- Load from Mem
        is_regWrite <= '1';         -- regWE on
        is_memWE    <= '0';         -- memWE off
        wait until rising_edge(is_clk);   


        ------ add  x1, x1, x2 ------
        is_rd       <= "00001";     -- x1
        is_rs1      <= "00001";     -- x1
        is_rs2      <= "00010";     -- x2
        -- No Imm needed
        is_mem_o_alu    <= '0';       -- Load from ALU
        is_ALUSrc   <= '0';         -- Use registers only
        is_regWrite <= '1';         -- regWE on
        is_memWE    <= '0';         -- memWE off
        wait until rising_edge(is_clk);


        ------ sw   x1, 4(x26) ------
        is_rd       <= "00000";     -- x0. Not needed. Here to be safe
        is_rs1      <= "11010";     -- &B = x26
        is_rs2      <= "00001";     -- x1
        is_Imm      <= x"004";      -- 4(x)
        -- is_mem_o_alue            -- doesn't matter
        is_ALUSrc   <= '1';         -- Use imm Value (for addr offset)
        is_regWrite <= '0';         -- regWE off
        is_memWE    <= '1';         -- memWE on
        wait until rising_edge(is_clk);
        wait until rising_edge(is_clk);     -- Test is we can see the result of write by next clock cycle


        ------ lw   x2, 12(x25) ------
        is_rd       <= "00010";     -- x2
        is_rs1      <= "11001";     -- x25
        is_ALUSrc   <= '1';         -- Use imm Value (for addr offset)
        is_Imm      <= x"00C";      -- 11 | 00
        is_mem_o_alu  <= '1';       -- Load from Mem
        is_regWrite <= '1';         -- regWE on
        is_memWE    <= '0';         -- memWE off
        wait until rising_edge(is_clk);   


        ------ add  x1, x1, x2 ------
        is_rd       <= "00001";     -- x1
        is_rs1      <= "00001";     -- x1
        is_rs2      <= "00010";     -- x2
        -- No Imm needed
        is_mem_o_alu    <= '0';       -- Load from ALU
        is_ALUSrc   <= '0';         -- Use registers only
        is_regWrite <= '1';         -- regWE on
        is_memWE    <= '0';         -- memWE off
        wait until rising_edge(is_clk);


        ------ sw   x1, 8(x26) ------
        is_rd       <= "00000";     -- x0. Not needed. Here to be safe
        is_rs1      <= "11010";     -- &B = x26
        is_rs2      <= "00001";     -- x1
        is_Imm      <= x"008";      -- 8(x)
        -- is_mem_o_alue            -- doesn't matter
        is_ALUSrc   <= '1';         -- Use imm Value (for addr offset)
        is_regWrite <= '0';         -- regWE off
        is_memWE    <= '1';         -- memWE on
        wait until rising_edge(is_clk);
        wait until rising_edge(is_clk);     -- Test is we can see the result of write by next clock cycle

        
        ------ lw   x2, 16(x25) ------
        is_rd       <= "00010";     -- x2
        is_rs1      <= "11001";     -- x25
        is_ALUSrc   <= '1';         -- Use imm Value (for addr offset)
        is_Imm      <= x"010";      -- 1 00 | 00
        is_mem_o_alu  <= '1';       -- Load from Mem
        is_regWrite <= '1';         -- regWE on
        is_memWE    <= '0';         -- memWE off
        wait until rising_edge(is_clk);   


        ------ add  x1, x1, x2 ------
        is_rd       <= "00001";     -- x1
        is_rs1      <= "00001";     -- x1
        is_rs2      <= "00010";     -- x2
        -- No Imm needed
        is_mem_o_alu    <= '0';       -- Load from ALU
        is_ALUSrc   <= '0';         -- Use registers only
        is_regWrite <= '1';         -- regWE on
        is_memWE    <= '0';         -- memWE off
        wait until rising_edge(is_clk);


        ------ sw   x1, 12(x26) ------
        is_rd       <= "00000";     -- x0. Not needed. Here to be safe
        is_rs1      <= "11010";     -- &B = x26
        is_rs2      <= "00001";     -- x1
        is_Imm      <= x"00C";      -- 12(x)
        -- is_mem_o_alue            -- doesn't matter
        is_ALUSrc   <= '1';         -- Use imm Value (for addr offset)
        is_regWrite <= '0';         -- regWE off
        is_memWE    <= '1';         -- memWE on
        wait until rising_edge(is_clk);
        wait until rising_edge(is_clk);     -- Test is we can see the result of write by next clock cycle
        

        ------ lw   x2, 20(x25) ------
        is_rd       <= "00010";     -- x2
        is_rs1      <= "11001";     -- x25
        is_ALUSrc   <= '1';         -- Use imm Value (for addr offset)
        is_Imm      <= x"014";      -- 0101 00 | 00     (20)
        is_mem_o_alu  <= '1';       -- Load from Mem
        is_regWrite <= '1';         -- regWE on
        is_memWE    <= '0';         -- memWE off
        wait until rising_edge(is_clk);   


        ------ add  x1, x1, x2  ------
        is_rd       <= "00001";     -- x1
        is_rs1      <= "00001";     -- x1
        is_rs2      <= "00010";     -- x2
        -- No Imm needed
        is_mem_o_alu    <= '0';       -- Load from ALU
        is_ALUSrc   <= '0';         -- Use registers only
        is_regWrite <= '1';         -- regWE on
        is_memWE    <= '0';         -- memWE off
        wait until rising_edge(is_clk);


        ------ sw   x1, 16(x26) ------
        is_rd       <= "00000";     -- x0. Not needed. Here to be safe
        is_rs1      <= "11010";     -- &B = x26
        is_rs2      <= "00001";     -- x1
        is_Imm      <= x"010";      -- 16(x)
        -- is_mem_o_alue            -- doesn't matter
        is_ALUSrc   <= '1';         -- Use imm Value (for addr offset)
        is_regWrite <= '0';         -- regWE off
        is_memWE    <= '1';         -- memWE on
        wait until rising_edge(is_clk);
        wait until rising_edge(is_clk);     -- Test is we can see the result of write by next clock cycle


        ------ lw   x2, 24(x25) ------
        is_rd       <= "00010";     -- x2
        is_rs1      <= "11001";     -- x25
        is_ALUSrc   <= '1';         -- Use imm Value (for addr offset)
        is_Imm      <= x"018";      -- 0110 00 | 00     (24)
        is_mem_o_alu  <= '1';       -- Load from Mem
        is_regWrite <= '1';         -- regWE on
        is_memWE    <= '0';         -- memWE off
        wait until rising_edge(is_clk);   


        ------ add  x1, x1, x2 ------
        is_rd       <= "00001";     -- x1
        is_rs1      <= "00001";     -- x1
        is_rs2      <= "00010";     -- x2
        -- No Imm needed
        is_mem_o_alu    <= '0';       -- Load from ALU
        is_ALUSrc   <= '0';         -- Use registers only
        is_regWrite <= '1';         -- regWE on
        is_memWE    <= '0';         -- memWE off
        wait until rising_edge(is_clk);


        ------ addi x27, x0, 512 ------
        is_rd       <= "11011";     -- x27
        is_rs1      <= "00000";     -- x0
        -- is_rs2 not needed
        is_Imm      <= x"200";      -- 0010 0000 0000 (512)
        is_mem_o_alu    <= '0';       -- Load from ALU
        is_ALUSrc   <= '1';         -- Use Imm value
        is_regWrite <= '1';         -- regWE on
        is_memWE    <= '0';         -- memWE off
        wait until rising_edge(is_clk);

       
        ------ sw   x1, -4(x27) ------
        is_rd       <= "00000";     -- x0. Not needed. Here to be safe
        is_rs1      <= "11011";     -- &B[64] = x27
        is_rs2      <= "00001";     -- x1
        is_Imm      <= x"004";      -- 4(x)
        nAddSub     <= '1';         -- Negative 4 offset
        -- is_mem_o_alue            -- doesn't matter
        is_ALUSrc   <= '1';         -- Use imm Value (for addr offset)
        is_regWrite <= '0';         -- regWE off
        is_memWE    <= '1';         -- memWE on
        wait until rising_edge(is_clk);
        wait until rising_edge(is_clk);     -- Test is we can see the result of write by next clock cycle


        ------ sw   x1, -4(x27) ------
        is_rd       <= "00000";     -- x0. Not needed. Here to be safe
        is_rs1      <= "11011";     -- &B[64] = x27
        is_rs2      <= "00001";     -- x1
        is_Imm      <= x"004";      -- 4(x)
        nAddSub     <= '1';         -- Negative 4 offset
        -- is_mem_o_alue            -- doesn't matter
        is_ALUSrc   <= '1';         -- Use imm Value (for addr offset)
        is_regWrite <= '0';         -- regWE off
        is_memWE    <= '1';         -- memWE on
        wait until rising_edge(is_clk);
        wait until rising_edge(is_clk);     -- Test is we can see the result of write by next clock cycle
        


        ------ lw, x4, 4(x25)
        is_rd       <= "00100";     -- x4
        is_rs1      <= "11001";     -- x25
        is_ALUSrc   <= '1';         -- Use imm Value (for addr offset)
        is_Imm      <= x"004";      -- 0110 00 | 00     (24) WRONG
        nAddSub     <= '0';         -- Positve 4 offset
        is_mem_o_alu  <= '1';       -- Load from Mem
        is_regWrite <= '1';         -- regWE on
        is_memWE    <= '0';         -- memWE off
        wait until rising_edge(is_clk);   

        
        wait;
    end process;
end architecture;






-- I fixed all of the compilation issues, but I got an error loading the design when trying to simulate it. At line 64. 

-- nvm I fixed the error. I had a mismatch in port direction. 

-- Can you help me with all of these warnings. I don't think I am worries about the warning before the run 2000. I think that one is just wanring me that the simulation is running slow because of it's failure to optimize something or something. Anyways, the waveform also has a lot of red which doesn't make me too hopeful for the CPU working. But maybe it is the warnings.

-- I gave you all my updated code again. Can you check out the warnings and see what I am doing wrong. Can you also check my test cases for tb_datapath2, and the data flow on my data path2, test bench for data path 2, and the datapath 1 for 2.  Like can you basically figure out what is going wrong?