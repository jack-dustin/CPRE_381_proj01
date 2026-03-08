-- Isaiah Pridie
-- CprE 381 project01 - OR Logic for ALU
-- 3.8.2026,    1:25 AM

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity proj01_ALU is
    generic(N : natrual := 32); -- Override all generics in this file with this value
    port(i_A        : in  std_logic_vector(31 downto 0);    -- RS1
         i_B        : in  std_logic_Vector(31 downto 0);    -- RS2 or IMM
         i_ALUctl   : in  std_logic_vector(3 downto 0);     -- All control signals we are supposed to need
            -- LeftMost bit of o_alu_op from Excel is (3)
            -- i_ALUct1(3) = funct3(1)      -- Used for mux, 
            -- i_ALUct1(2) = funct3(2)      -- Used for mux, Shift direction
            -- i_ALUct1(1) = funct3(0)      -- Used for mux
            -- i_ALUct1(0) = funct7(5)      -- Used for nAddSub, Shift s_sex
         o_ALUout   : out std_logic_Vector(31 downto 0);
         -- Later:
            -- o_zero;
            -- o_lt;
            );
end proj01_ALU;

architecture structural of proj01_ALU is

    -- Establish Signals/Wires/Constants
    signal s_andOUT     : std_logic_vector(31 downto 0);
    signal s_xorOUT     : std_logic_vector(31 downto 0);
    signal s_orOUT      : std_logic_vector(31 downto 0);
    signal s_shiftOUT   : std_logic_vector(31 downto 0);
    signal s_AddSubOUT  : std_logic_vector(31 downto 0);

    signal s_Mux_0t2    : std_logic_Vector(31 downto 0);
    signal s_Mux_1t2    : std_logic_Vector(31 downto 0);
    -- Components:
    component and_ALU is
        generic(N : natural := 32); -- Make this file flexible because why not
        port(i_aDA  : in  std_logic_vector(N-1 downto 0);
             i_aDB  : in  std_logic_vector(N-1 downto 0);
             o_aDo  : out std_logic_Vector(N-1 downto 0));
    end component;
    
    component xor_ALU is
        generic(N : natural := 32); -- Make this file flexible because why not
        port(i_xDA  : in  std_logic_vector(N-1 downto 0);
             i_xDB  : in  std_logic_vector(N-1 downto 0);
             o_xDo  : out std_logic_Vector(N-1 downto 0));
    end component;

    component or_ALU is
        generic(N : natural := 32); -- Make this file flexible because why not
        port(i_oDA  : in  std_logic_vector(N-1 downto 0);
             i_oDB  : in  std_logic_vector(N-1 downto 0);
             o_oDo  : out std_logic_Vector(N-1 downto 0));
    end component;

    component shifter is
        port(i_vect_A   : in  std_logic_vector(31 downto 0);     -- Input A (RS1)
             i_vect_B   : in  std_logic_vector(31 downto 0);     -- Input B (RS2 or Imm)
             c_extend   : in  std_logic;     -- Controls Zero or Sign extending | funct7(5)
             c_Shift    : in  std_logic;     -- Controls shifting Left or Right | funct3(2)
             o_vect_Out : out std_logic_vector(31 downto 0) );
    end component;

    component addSub is
        generic (N : integer := 32);        -- use 32 for now. Value not specified in Lab Doc
        port(i_Da       : in  std_logic_vector(N-1 downto 0);
             i_Db       : in  std_logic_vector(N-1 downto 0);
             nAdd_Sub   : in  std_logic;    -- used as control/carry
             o_Sum      : out std_logic_vector(N-1 downto 0);
             o_Car      : out std_logic);   -- used for last carry output
    end component;

    component busMux_2t1 is
        port(i_dZero  : in std_logic_vector(31 downto 0);
             i_dOne   : in std_logic_vector(31 downto 0);
             ALUSrc   : in std_logic; -- select line. It's named poorly. I wasn't thinking ahead
             o_dOUT   : out std_logic_vector(31 downto 0));
    end component;

    component busMux_4t1 is 
        port(i_Da   : in  std_logic_vector(31 downto 0);    -- Input 1
             i_Db   : in  std_logic_vector(31 downto 0);    -- Input 2
             i_Dc   : in  std_logic_vector(31 downto 0);    -- Input 3
             i_Dd   : in  std_logic_vector(31 downto 0);    -- Input 4
             C_S0   : in  std_logic;                        -- Sel line 0
             C_S1   : in  std_logic;                        -- Sel line 1
             o_Do   : out std_logic_vector(31 downto 0) );  -- Output
    end component;
    
begin

    -- Instantiate AND ALU fucntionality
    INST_AND: and_ALU port map(
        i_aDA   => i_A,
        i_aDB   => i_B,
        o_aDo   => s_andOUT);

    -- Instantiate XOR ALU functionality
    INST_XOR: xor_ALU port map(
        i_xDA   => i_A,
        i_xDB   => i_B,
        o_xDo   => s_xorOUT);

    -- Instantiate OR ALU functionality
    INST_OR: or_ALU port map(
        i_oDA   => i_A,
        i_oDB   => i_B,
        o_oDo   => s_orOUT);

    -- Instantiate shifting ALU functionality
    INST_SHIFT: Shifter port map(
        i_vect_A    => i_A,
        i_vect_B    => i_B,
        c_extend    => i_ALUct1(0),     -- funct7(5)    When 1 sign extend, else zero extend
        c_Shift     => i_ALUct1(2),     -- funct3(2)    When 1 continue, else reverse bit order
        o_vect_Out  => s_shiftOUT);

    -- Instantiate Add/Sub ALU functionality
    INST_ADDSUB: addSub port map(
        i_Da        => i_A,
        i_Db        => i_B,
        nAdd_Sub    => i_ALUct1(0),     -- funct7(5)
        o_Sum       => s_AddSubOUT,     -- Sum is output vector
        o_Car       => open);           -- Carry is last carry bit. Leave open - We don't need it rn
    

    -- Use busMux_4t1 and busMux_2t1 for busMux_5t1
    -- 2x [4t1 Mux]  ->  1x [2t1 mux]  ->  output
        -- Da0  000  Add/Sub
        -- Db0  001  Shift
        -- Dc0  010  0x00000000  (Will be slt later)
        -- Dd0  011  Shift...?   (for now...?)...? (I think this is o_zero later)
        -- Da1  100  XORn
        -- Db1  101  Shift
        -- Dc1  110  ORn
        -- Dd1  111  ANDn

    -- LeftMost bit of o_alu_op from Excel is (3)
        -- i_ALUct1(3) = funct3(1)      -- Used for mux, 
        -- i_ALUct1(2) = funct3(2)      -- Used for mux, Shift direction
        -- i_ALUct1(1) = funct3(0)      -- Used for mux
        -- i_ALUct1(0) = funct7(5)      -- Used for nAddSub, Shift s_sex

    -- Instantiate busMuxes
    INST_BUSMUX_4t1_0: busMux_451 port map(
        i_Da    => s_AddSubOUT,     -- Input AddSub
        i_Db    => s_shiftOUT,      -- Input Left Shift
        i_Dc    => x"00000000",     -- Become slt later
        i_Dd    => s_shiftOUT,      -- (Become o_zero later?)
        C_S0    => i_ALUct1(1),     -- funct3(0)
        C_S1    => i_ALUct1(3),     -- funct3(1)
        o_Do    => s_Mux_0t2);      -- Go to port 0 of 2t1 mux

    INST_BUSMUX_4t1_1: busMux_451 port map(
        i_Da    => s_xorOUT,        -- Input XOR
        i_Db    => s_shiftOUT,      -- Input Right Shift
        i_Dc    => s_orOUT,         -- Input OR
        i_Dd    => s_andOUT,        -- Input AND
        C_S0    => i_ALUct1(1),     -- funct3(0)
        C_S1    => i_ALUct1(3),     -- funct3(1)
        o_Do    => s_Mux_1t2);      -- Go to port 1 of 2t1 mux

    INST_BUSMUX_2t1_2: busMux_2t1 port map(
        i_dZero => s_Mux_0t2,       -- Mux4t1_0 input
        i_dOne  => s_Mux_1t2,       -- Mux4t1_1 input
        ALUSrc  => i_ALUct1(2),     -- funct3(2)
        o_dOUT  => o_ALUout);       -- Final ALU Output

end architecture;
