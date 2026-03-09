-- Isaiah Pridie
-- CprE 381 project01 Fetcher component thing
    -- This file contains:
        -- PC Register
        -- PC Register Update Logic
        -- All the necessary ports for clocks, resets, controls, and I/O
-- Start Date: 3.2.2026,    5:43 PM

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity proj1_fetch is 
    port(i_CLK      : in std_logic;
         i_RST_PC   : in std_logic;     -- Need different reset* (this one); We need to reset register to 0x0040.0000 not 0x0000.0000
         i_imm      : in std_logic_vector(31 downto 0);     -- imm AFTER SIGN-EXTENDING AND MUXING
         c_PC_add   : in std_logic;                         -- Control bit for choosing between "+4" and "+imm"
         o_PC       : out std_logic_vector(31 downto 0) );  -- Output from PC register to Instruction memory
end proj1_fetch;

architecture structural of proj1_fetch is 
    
    -- Wire/Signal/constant declarations. Component declarations afterwards
    constant N : natural := 32;
    signal is_PC          : std_logic_vector(31 downto 0);    -- Carries PC contents to adders
    signal os_busMux1     : std_logic_vector(31 downto 0);    -- Signal carries from busMux_1 to busMux_2
    signal os_busMux2     : std_logic_vector(31 downto 0);    -- Signal carries from busMux_2 to PC register
    signal s_PC_4_mux     : std_logic_vector(31 downto 0);    -- Signal carries "PC + 4" result to busMux(0)
    signal s_PC_imm_mux   : std_logic_vector(31 downto 0);    -- Signal carries "PC + imm" result to busMux(1)

    component basic_adder_n is 
        generic (N: integer := 4);      -- Defined 4 by default in basic_adder_n folder
        port(i_aB0   : in std_logic_vector(N-1 downto 0);   -- Data in 0
             i_aB1   : in std_logic_vector(N-1 downto 0);   -- Data in 1
             o_S     : out std_logic_vector(N-1 downto 0);  -- Output Sum
             i_C     : in std_logic;    -- Not Bus. Used for a control*
             o_C     : out std_logic ); -- Not Bus. Final Carry Output)
    end component;

    component busMux_2t1 is
        port(i_dZero    : in std_logic_vector(31 downto 0); 
             i_dOne     : in std_logic_vector(31 downto 0);
             ALUSrc     : in std_logic; -- select line
             o_dOUT     : out std_logic_vector(31 downto 0));
    end component;

    component reg_n is
        generic (N : integer := 32);
        port(i_CLK   : in std_logic;                          -- Clock input
             i_RST   : in std_logic;                          -- Reset input
             i_WE    : in std_logic;                          -- Write enable input
             i_D     : in std_logic_vector(N-1 downto 0);     -- (Bus) Data value input
             o_Q     : out std_logic_vector(N-1 downto 0));   -- (Bus) Data value output
    end component; 

    -- starting structuring the structural circuit with structural methods
    -- (instantiate components)
    -- Component => Entity Ports/Signals
    begin   

        -- Choose between "PC + 4" and "PC + imm"
        INST_BUSMUX_1: busMux_2t1
        port map(i_dZero    => s_PC_4_mux,        -- Input 0
                 i_dOne     => s_PC_imm_mux,      -- Input 1
                 ALUSrc     => c_PC_add,          -- Control/Select line
                 o_dOUT     => os_busMux1);       -- Going to PC Register

        INST_BUSMUX_2: busMux_2t1
        port map(i_dZero    => os_busMux1,      -- Default value through (busMux_1 output)
                 i_dOne     => x"00400000",     -- Reset PC Register to default value
                 ALUSrc     => i_RST_PC,        -- Reset signal/select line for PC register
                 o_dOUT     => os_busMux2);     -- Output final result to PC Register

        INST_REG_N: reg_n
        port map(i_CLK  => i_CLK,
                 i_RST  => '0',             -- Prevent register from going to 0x0000.0000 
                 i_WE   => '1',             -- Should always be 1
                 i_D    => os_busMux2,      -- Input from busMux
                 o_Q    => is_PC);          -- Output of PC register (address going to instruction memory)

        o_PC    <= is_PC;   -- Assign output with the output signal

        -- PC + 4 into (0)
        INST_ADDER_N_4: basic_adder_n     
        generic map (N => N)
        port map(i_aB0  => is_PC,
                 i_aB1  => x"00000004",    -- d'4' 
                 o_S    => s_PC_4_mux,     -- Signal carries to busMux(0)
                 i_C    => '0',            -- Hardcode carry in bit to 0
                 o_C    =>  open);         -- "open" is used in VHDL to indicate an output not connected to anything

        -- PC + imm into (1)
        INST_ADDER_N_IMM: basic_adder_n     
        generic map (N => N)
        port map(i_aB0  => is_PC,
                 i_aB1  => i_imm,
                 o_S    => s_PC_imm_mux,    -- Signal carries to busMux(1)
                 i_C    => '0',             -- Hardcode carry in bit to 0
                 o_C    => open);           -- "open" is used in VHDL to indicate an output not connected to anything

end structural;
