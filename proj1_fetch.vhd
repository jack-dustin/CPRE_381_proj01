-- Isaiah Pridie
-- CprE 381 project01 Fetcher component thing
-- Start Date: 3.2.2026,    5:43 PM

-- TODO: 
    -- Import Register component for PC register
    -- Add wire to connect busMux output to PC register
    -- Finish port maps in the instantiation area
    
    -- Obviously Debug
    -- Obviously TestBench after this file compiles

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity proj1_fetch is 
    port(i_CLK      : in std_logic;
         i_RST      : in std_logic;
         i_imm      : in std_logic_vector(31 downto 0);     -- imm AFTER SIGN-EXTENDING AND MUXING
         c_PC_add   : in std_logic; -- Control bit for choosing between "+4" and "+imm"
         o_PC       : out std_logic_vector(31 downto 0) );    -- Output from PC register to Instruction memory
end proj1_fetch;

architecture structural of proj1_fetch is 
    
    -- Wire/Signal declarations. Component declarations afterwards
    signal i_PC         : std_logic_vector(31 downto 0);    -- Carries PC contents to adders
    signal PC_4_mux     : std_logic_vector(31 downto 0);    -- Signal carries "PC + 4" result to busMux(0)
    signal PC_imm_mux   : std_logic_vector(31 downto 0);    -- Signal carries "PC + imm" result to busMux(1)

    component basic_adder_n is 
        generic (N: natural := 4);      -- Defined 4 by default in basic_adder_n folder
        port(i_aB0   : in std_logic_vector(N-1 downto 0);   -- Data in 0
             i_aB1   : in std_logic_vector(N-1 downto 0);   -- Data in 1
             o_S     : out std_logic_vector(N-1 downto 0);  -- Output Sum
             i_C     : in std_logic;    -- Not Bus. Used for a control*
             o_C     : out std_logic ); -- Not Bus. Final Carry Output)
    end component;

    component busMux2t1 is
        port(i_dZero    : in std_logic_vector(31 downto 0); 
             i_dOne     : in std_logic_vector(31 downto 0);
             ALUSrc     : in std_logic; -- select line
             o_dOUT     : out std_logic_vector(31 downto 0));
    end component;

    -- starting structuring the structural circuit with structural methods
    -- (instantiate components)
    -- Component => Entity Ports/Signals
    begin   

        -- Choose between "PC + 4" and "PC + imm"
        INST_BUSMUX: busMux2t1 is
        port map(i_dZero    => ,
                 i_dOne     => ,
                 ALUSrc     => ,
                 o_dOUT     => );

        -- PC + 4 into (0)
        INST_ADDER_N: basic_adder_n     
        generic map (N => N)
        port map(i_aB0  => i_PC,
                 i_aB1  => ,
                 o_S    => PC_4_mux,
                 i_C    => '0',     -- Hardcode carry in bit to 0
                 o_C    =>  );

        -- PC + imm into (1)
        INST_ADDER_N: basic_adder_n     
        generic map (N => N)
        port map(i_aB0  => i_PC,
                 i_aB1  => ,
                 o_S    => PC_imm_mux,
                 i_C    => '0',     -- Hardcode carry in bit to 0
                 o_C    =>  );

end structural;
