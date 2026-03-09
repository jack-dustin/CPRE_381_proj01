-- Isaiah Pridie
-- CprE 3810 proj01 tb_ALU
-- Start Date: 3.8.2026,    5:57 PM

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_proj01_ALU is     -- Leave empty. ALU is doesn't depend on the clock  (asynchronous)
end entity;


architecture proj01_ALU of tb_proj01_ALU is

    -- Signals/Wires/Waveforms/Constants
    signal s_ALUctrl    : std_logic_vector(3 downto 0);     -- 4 bits   Reworked vector signal
    signal s_funct3_2   : std_logic;  -- Bit 3/3
    signal s_funct3_1   : std_logic;  -- Bit 2/3
    signal s_funct3_0   : std_logic;  -- Bit 1/3
    signal s_funct7_5   : std_logic;    -- 1 bit. Used for s_ex, ALU_mux, nAddSub
    signal s_iA         : std_logic_vector(31 downto 0);    -- input A (RS1)
    signal s_iB         : std_logic_vector(31 downto 0);    -- input B (RS2 || Imm)
    signal s_oOut       : std_logic_vector(31 downto 0);    -- Output of ALU
    signal t_ALUctrl    : std_logic_vector(3 downto 0);     -- 4 bits

    component proj01_ALU is
    port(i_A        : in  std_logic_vector(31 downto 0);    -- RS1
         i_B        : in  std_logic_vector(31 downto 0);    -- RS2 or IMM
         i_ALUctl   : in  std_logic_vector(3 downto 0);     -- Control Signals
         o_ALUout   : out std_logic_vector(31 downto 0) );  -- Output
    end component;
        
    begin
    DUT: proj01_ALU
        -- Component => Signal
        port map(i_A        => s_iA,
                i_B        => s_iB,
                i_ALUctl   => t_ALUctrl,
                o_ALUout   => s_oOut );

        s_funct3_2  <= t_ALUctrl(2);
        s_funct3_1  <= t_ALUctrl(3);
        s_funct3_0  <= t_ALUctrl(1);
        s_funct7_5  <= t_ALUctrl(0);
        
        -- s_ALUctrl = [funct3_2, funct3_1, funct3_0, funct7_5]
            -- Going to make TestBenches a lot faster to make
        s_ALUctrl(3)    <= t_ALUctrl(2);
        s_ALUctrl(2)    <= t_ALUctrl(3);
        s_ALUctrl(1)    <= t_ALUctrl(1);
        s_ALUctrl(0)    <= t_ALUctrl(0);

    Test_Cases: process
    begin
    -- i_ALUctl(3) = funct3(1)      -- Used for mux, 
    -- i_ALUctl(2) = funct3(2)      -- Used for mux, Shift direction
    -- i_ALUctl(1) = funct3(0)      -- Used for mux
    -- i_ALUctl(0) = funct7(5)      -- Used for nAddSub, Shift s_ex

    -- Top 3 bits [3:1] of s_ALUctl
    -- 000_  Add/Sub
    -- 001_  Shift Left      
    -- 010_  0x00000000
    -- 011_  Shift...? Left? 
    -- 100_  XORn
    -- 101_  Shift Right
    -- 110_  ORn
    -- 111_  ANDn

    -- s_ALUctl(3) = funct3(1)  -- Used for mux, 
    -- s_ALUctl(2) = funct3(2)  -- Used for mux, Shift direction
    -- s_ALUctl(1) = funct3(0)  -- Used for mux
    -- s_ALUctl(0) = funct7(5)  -- Used for nAddSub, Shift s_ex

        --------------------------------
        -------- AND Unit --------------
        -- Test Case 1: 0 AND 0
        s_ALUctrl   <= x"E";        -- 1110
        s_iA        <= x"00000000"; -- 0000 0000 0000 0000 . . . 
        s_iB        <= x"00000000"; -- 0000 0000 0000 0000 . . .
        wait for 5 ns;
        -- Expect: 0x0000 0000        

        -- Test Case 2: 1 AND 1
        s_ALUctrl   <= x"E";        -- 1110
        s_iA        <= x"FFFFFFFF"; -- 1111 1111 1111 1111 . . . 
        s_iB        <= x"FFFFFFFF"; -- 1111 1111 1111 1111 . . .
        wait for 5 ns;
        -- Expect: 0xFFFF FFFF

        -- Test Case 3: 0 AND 1
        s_ALUctrl   <= x"E";        -- 1110
        s_iA        <= x"00000000"; -- 0000 0000 0000 0000 . . . 
        s_iB        <= x"FFFFFFFF"; -- 1111 1111 1111 1111 . . .
        wait for 5 ns;
        -- Expect: 0x0000 0000

        -- Test Case 4: 1 AND 0
        s_ALUctrl   <= x"E";        -- 1110
        s_iA        <= x"FFFFFFFF"; -- 1111 1111 1111 1111 . . .
        s_iB        <= x"00000000"; -- 0000 0000 0000 0000 . . . 
        wait for 5 ns;
        -- Expect: 0x0000 0000

        -- Test Case 5: F0F0... AND 0F0F...
        s_ALUctrl   <= x"E";        -- 1110
        s_iA        <= x"F0F0F0F0"; -- 1111 0000 1111 0000 . . .
        s_iB        <= x"0F0F0F0F"; -- 0000 1111 0000 1111 . . . 
        wait for 5 ns;
        -- Expect: 0x0000 0000

        -- Test Case 6: 0F0F... AND F0F0...
        s_ALUctrl   <= x"E";        -- 1110
        s_iA        <= x"0F0F0F0F"; -- 0000 1111 0000 1111 . . .
        s_iB        <= x"F0F0F0F0"; -- 1111 0000 1111 0000 . . . 
        wait for 5 ns;
        -- Expect: 0x0000 0000

    wait for 20 ns;     -- Make it more obvious when the next test starts

        --------------------------------
        -------- XOR Unit --------------
        -- Test Case 1: 0 XOR 0
        s_ALUctrl   <= x"8";        -- 1000
        s_iA        <= x"00000000"; -- 0000 0000 0000 0000 . . . 
        s_iB        <= x"00000000"; -- 0000 0000 0000 0000 . . .
        wait for 5 ns;
        -- Expect: 0x0000 0000        

        -- Test Case 2: 1 XOR 1
        s_ALUctrl   <= x"8";        -- 1000
        s_iA        <= x"FFFFFFFF"; -- 1111 1111 1111 1111 . . . 
        s_iB        <= x"FFFFFFFF"; -- 1111 1111 1111 1111 . . .
        wait for 5 ns;
        -- Expect: 0x0000 0000

        -- Test Case 3: 0 XOR 1
        s_ALUctrl   <= x"8";        -- 1000
        s_iA        <= x"00000000"; -- 0000 0000 0000 0000 . . . 
        s_iB        <= x"FFFFFFFF"; -- 1111 1111 1111 1111 . . .
        wait for 5 ns;
        -- Expect: 0xFFFF FFFF

        -- Test Case 4: 1 XOR 0
        s_ALUctrl   <= x"8";        -- 1000
        s_iA        <= x"FFFFFFFF"; -- 1111 1111 1111 1111 . . .
        s_iB        <= x"00000000"; -- 0000 0000 0000 0000 . . . 
        wait for 5 ns;
        -- Expect: 0xFFFF FFFF

        -- Test Case 5: F0F0... XOR 0F0F...
        s_ALUctrl   <= x"8";        -- 1000
        s_iA        <= x"F0F0F0F0"; -- 1111 0000 1111 0000 . . .
        s_iB        <= x"0F0F0F0F"; -- 0000 1111 0000 1111 . . . 
        wait for 5 ns;
        -- Expect: 0xFFFF FFFF

        -- Test Case 6: 0F0F... XOR F0F0...
        s_ALUctrl   <= x"8";        -- 1000
        s_iA        <= x"0F0F0F0F"; -- 0000 1111 0000 1111 . . .
        s_iB        <= x"F0F0F0F0"; -- 1111 0000 1111 0000 . . . 
        wait for 5 ns;
        -- Expect: 0xFFFF FFFF

    wait for 20 ns;     -- Make it more obvious when the next test starts

        --------------------------------
        -------- OR Unit ---------------
        -- Test Case 1: 0 OR 0
        s_ALUctrl   <= x"C";        -- 1100
        s_iA        <= x"00000000"; -- 0000 0000 0000 0000 . . . 
        s_iB        <= x"00000000"; -- 0000 0000 0000 0000 . . .
        wait for 5 ns;
        -- Expect: 0x0000 0000        

        -- Test Case 2: 1 OR 1
        s_ALUctrl   <= x"C";        -- 1100
        s_iA        <= x"FFFFFFFF"; -- 1111 1111 1111 1111 . . . 
        s_iB        <= x"FFFFFFFF"; -- 1111 1111 1111 1111 . . .
        wait for 5 ns;
        -- Expect: 0xFFFF FFFF

        -- Test Case 3: 0 OR 1
        s_ALUctrl   <= x"C";        -- 1100
        s_iA        <= x"00000000"; -- 0000 0000 0000 0000 . . . 
        s_iB        <= x"FFFFFFFF"; -- 1111 1111 1111 1111 . . .
        wait for 5 ns;
        -- Expect: 0xFFFF FFFF

        -- Test Case 4: 1 OR 0
        s_ALUctrl   <= x"C";        -- 1100
        s_iA        <= x"FFFFFFFF"; -- 1111 1111 1111 1111 . . .
        s_iB        <= x"00000000"; -- 0000 0000 0000 0000 . . . 
        wait for 5 ns;
        -- Expect: 0xFFFF FFFF

        -- Test Case 5: F0F0... OR 0F0F...
        s_ALUctrl   <= x"C";        -- 1100
        s_iA        <= x"F0F0F0F0"; -- 1111 0000 1111 0000 . . .
        s_iB        <= x"0F0F0F0F"; -- 0000 1111 0000 1111 . . . 
        wait for 5 ns;
        -- Expect: 0xFFFF FFFF

        -- Test Case 6: 0F0F... OR F0F0...
        s_ALUctrl   <= x"C";        -- 1100
        s_iA        <= x"0F0F0F0F"; -- 0000 1111 0000 1111 . . .
        s_iB        <= x"F0F0F0F0"; -- 1111 0000 1111 0000 . . . 
        wait for 5 ns;
        -- Expect: 0xFFFF FFFF

    wait for 20 ns;     -- Make it more obvious when the next test starts

        --------------------------------
        -------- Adder/Sub Unit --------
        -- Test Case 1: Add 0
        s_ALUctrl   <= x"0";        -- 0000
        s_iA        <= x"F0F0F0F0"; -- 1111 0000 1111 0000 . . . 
        s_iB        <= x"00000000"; -- 0000 0000 0000 0000 . . .
        wait for 5 ns;
        -- Expect: s_iA        

        -- Test Case 2: Add 0 to 0
        s_ALUctrl   <= x"0";        -- 0000
        s_iA        <= x"00000000"; -- 0000 0000 0000 0000 . . . 
        s_iB        <= x"00000000"; -- 0000 0000 0000 0000 . . .
        wait for 5 ns;
        -- Expect: 0x0000 0000        

        -- Test Case 3: Add F0F0... to 0F0F...
        s_ALUctrl   <= x"0";        -- 0000
        s_iA        <= x"F0F0F0F0"; -- 1111 0000 1111 0000 . . . 
        s_iB        <= x"0F0F0F0F"; -- 0000 1111 0000 1111 . . .
        wait for 5 ns;
        -- Expect: 0xFFFF FFFF

        -- Test Case 4: Add 0F0F... to F0F0...
        s_ALUctrl   <= x"0";        -- 0000
        s_iA        <= x"0F0F0F0F"; -- 0000 1111 0000 1111. . . 
        s_iB        <= x"F0F0F0F0"; -- 1111 0000 1111 0000. . .
        wait for 5 ns;
        -- Expect: 0xFFFF FFFF

        -- Test Case 5: Overflow it
        s_ALUctrl   <= x"0";        -- 0000
        s_iA        <= x"FFFFFFFF"; -- 1111 1111 1111 1111 . . . 
        s_iB        <= x"00000001"; -- . . . 0000 0000 0000 0001
        wait for 5 ns;
        -- Expect: 0x0000 0000

        -- Test Case 6: Subtract 1 from 0
        s_ALUctrl   <= x"1";        -- 0001
        s_iA        <= x"00000000"; -- 0000 0000 0000 0000 . . . 
        s_iB        <= x"00000001"; -- . . . 0000 0000 0000 0001
        wait for 5 ns;
        -- Expect: 0xFFFF FFFF

        -- Test Case 7: Subtract FF... from FF...
        s_ALUctrl   <= x"1";        -- 0001
        s_iA        <= x"FFFFFFFF"; -- 1111 1111 1111 1111 . . . 
        s_iB        <= x"FFFFFFFF"; -- 1111 1111 1111 1111. . .
        wait for 5 ns;
        -- Expect: 0x0000 0000

        -- Test Case 8: Subtract 0 from 0
        s_ALUctrl   <= x"1";        -- 0001
        s_iA        <= x"00000000"; -- 0000 0000 0000 0000 . . . 
        s_iB        <= x"00000000"; -- 0000 0000 0000 0000. . .
        wait for 5 ns;
        -- Expect: 0x0000 0000

    wait for 20 ns;     -- Make it more obvious when the next test starts

        --------------------------------
        -------- Shifter Unit ----------
        -- Test Case 1: Shift Left xF0F0... by 16 bits
        s_ALUctrl   <= x"2";        -- 0010     Shift Left
        s_iA        <= x"F0F0F0F0"; -- 1111 0000 1111 0000 . . . 
        s_iB        <= x"00000010"; -- . . . 0000 0000 0001 0000
        wait for 5 ns;
        -- Expect: 0xF0F0 0000

        -- Test Case 2: Shift Left x0F0F... by FFFF bits
        s_ALUctrl   <= x"2";        -- 0010     Shift Left
        s_iA        <= x"0F0F0F0F"; -- 0000 1111 0000 1111 . . . 
        s_iB        <= x"0000FFFF"; -- . . . 1111 1111 1111 1111
        wait for 5 ns;
        -- Expect: 0x8000 0000   Shift should max at 31 bits

        -- Test Case 3: Shift Left x00000001 by 1 bit
        s_ALUctrl   <= x"2";        -- 0010     Shift Left
        s_iA        <= x"00000001"; -- . . . 0000 0000 0000 0001
        s_iB        <= x"00000001"; -- . . . 0000 0000 0000 0001
        wait for 5 ns;
        -- Expect: 0x0000 0002

        -- Test Case 4: Shift Left x80000000 by 1 bit
        s_ALUctrl   <= x"2";        -- 0010     Shift Left
        s_iA        <= x"80000000"; -- 1000 0000 0000 0000 . . .
        s_iB        <= x"00000001"; -- . . . 0000 0000 0000 0001
        wait for 5 ns;
        -- Expect: 0x0000 0000

        -- Test Case 5: Shift Left xAAAAAAAA by 4 bits
        s_ALUctrl   <= x"2";        -- 0010     Shift Left
        s_iA        <= x"AAAAAAAA"; -- 1010 1010 1010 1010 . . .
        s_iB        <= x"00000004"; -- . . . 0000 0000 0000 0100
        wait for 5 ns;
        -- Expect: 0xAAAA AAA0

        -- Test Case 6: Shift Left x12345678 by 8 bits
        s_ALUctrl   <= x"2";        -- 0010     Shift Left
        s_iA        <= x"12345678"; -- 0001 0010 0011 0100 . . .
        s_iB        <= x"00000008"; -- . . . 0000 0000 0000 1000
        wait for 5 ns;
        -- Expect: 0x3456 7800 

    wait for 10 ns;     -- Make it more obvious when the next test starts

        -- Test Case 7: Shift Right xF0F0... by 4 bits (Zero Extend)
        s_ALUctrl   <= x"A";        -- 1010     Shift Right, Zero Extend
        s_iA        <= x"F0F0F0F0"; -- 1111 0000 1111 0000 . . .
        s_iB        <= x"00000004"; -- . . . 0000 0000 0000 0100
        wait for 5 ns;
        -- Expect: 0x0F0F 0F0F

        -- Test Case 8: Shift Right x80000000 by 1 bit (Zero Extend)
        s_ALUctrl   <= x"A";        -- 1010     Shift Right, Zero Extend
        s_iA        <= x"80000000"; -- 1000 0000 0000 0000 . . .
        s_iB        <= x"00000001"; -- . . . 0000 0000 0000 0001
        wait for 5 ns;
        -- Expect: 0x4000 0000

        -- Test Case 9: Shift Right xFFFFFFFF by 31 bits (Zero Extend)
        s_ALUctrl   <= x"A";        -- 1010     Shift Right, Zero Extend
        s_iA        <= x"FFFFFFFF"; -- 1111 1111 1111 1111 . . .
        s_iB        <= x"0000001F"; -- . . . 0000 0000 0001 1111
        wait for 5 ns;
        -- Expect: 0x0000 0001

        -- Test Case 10: Shift Right x12345678 by 8 bits (Zero Extend)
        s_ALUctrl   <= x"A";        -- 1010     Shift Right, Zero Extend
        s_iA        <= x"12345678"; -- 0001 0010 0011 0100 . . .
        s_iB        <= x"00000008"; -- . . . 0000 0000 0000 1000
        wait for 5 ns;
        -- Expect: 0x0012 3456

        -- Test Case 11: Shift Right x00000001 by 1 bit (Zero Extend)
        s_ALUctrl   <= x"A";        -- 1010     Shift Right, Zero Extend
        s_iA        <= x"00000001"; -- . . . 0000 0000 0000 0001
        s_iB        <= x"00000001"; -- . . . 0000 0000 0000 0001
        wait for 5 ns;
        -- Expect: 0x0000 0000

        -- Test Case 12: Shift Right x0F0F0F0F by FFFF bits (Zero Extend)
        s_ALUctrl   <= x"A";        -- 1010     Shift Right, Zero Extend
        s_iA        <= x"0F0F0F0F"; -- 0000 1111 0000 1111 . . .
        s_iB        <= x"0000FFFF"; -- . . . 1111 1111 1111 1111
        wait for 5 ns;
        -- Expect: 0x0000 0000   Shift should max at 31 bits

    wait for 10 ns;     -- Make it more obvious when the next test starts

        -- Test Case 13: Shift Right xF0F0... by 4 bits (One Extend)
        s_ALUctrl   <= x"B";        -- 1011     Shift Right, One Extend
        s_iA        <= x"F0F0F0F0"; -- 1111 0000 1111 0000 . . .
        s_iB        <= x"00000004"; -- . . . 0000 0000 0000 0100
        wait for 5 ns;
        -- Expect: 0xFF0F 0F0F

        -- Test Case 14: Shift Right x80000000 by 1 bit (One Extend)
        s_ALUctrl   <= x"B";        -- 1011     Shift Right, One Extend
        s_iA        <= x"80000000"; -- 1000 0000 0000 0000 . . .
        s_iB        <= x"00000001"; -- . . . 0000 0000 0000 0001
        wait for 5 ns;
        -- Expect: 0xC000 0000

        -- Test Case 15: Shift Right xFFFFFFFF by 31 bits (One Extend)
        s_ALUctrl   <= x"B";        -- 1011     Shift Right, One Extend
        s_iA        <= x"FFFFFFFF"; -- 1111 1111 1111 1111 . . .
        s_iB        <= x"0000001F"; -- . . . 0000 0000 0001 1111
        wait for 5 ns;
        -- Expect: 0xFFFF FFFF

        -- Test Case 16: Shift Right x12345678 by 8 bits (One Extend)
        s_ALUctrl   <= x"B";        -- 1011     Shift Right, One Extend
        s_iA        <= x"12345678"; -- 0001 0010 0011 0100 . . .
        s_iB        <= x"00000008"; -- . . . 0000 0000 0000 1000
        wait for 5 ns;
        -- Expect: 0xFF12 3456

        -- Test Case 17: Shift Right x00000001 by 1 bit (One Extend)
        s_ALUctrl   <= x"B";        -- 1011     Shift Right, One Extend
        s_iA        <= x"00000001"; -- . . . 0000 0000 0000 0001
        s_iB        <= x"00000001"; -- . . . 0000 0000 0000 0001
        wait for 5 ns;
        -- Expect: 0x8000 0000

        -- Test Case 18: Shift Right x0F0F0F0F by FFFF bits (One Extend)
        s_ALUctrl   <= x"B";        -- 1011     Shift Right, One Extend
        s_iA        <= x"0F0F0F0F"; -- 0000 1111 0000 1111 . . .
        s_iB        <= x"0000FFFF"; -- . . . 1111 1111 1111 1111
        wait for 5 ns;
        -- Expect: 0xFFFF FFFF   Shift should max at 31 bits

    wait;
    end process;
end architecture;
