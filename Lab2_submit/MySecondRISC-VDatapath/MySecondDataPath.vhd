-- Isaiah Pridie
-- Cpre 3810 Lab2 Part 7
-- Start Date: 2.22.2026,   9:19 PM

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MySecondDataPath is
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
end entity;


architecture structural of MySecondDataPath is
    -- establish wires/signals/constants:
    constant DATA_WIDTH     : natural := 32;
    constant ADDR_WIDTH     : natural :=10;
    signal extender_t_adder : std_logic_vector(31 downto 0) := (others => '0'); -- initi
    signal memAddr          : std_logic_vector(9  downto 0);        -- "ADDR_WIDTH : natrual := 10"
    signal memData          : std_logic_vector(31 downto 0);        -- "DATA_WIDTH : natrual := 32"
    signal memOut           : std_logic_vector(31 downto 0);        -- Output of memory into mux

-- Establish components
    component Lab2_DataPath1_for2 is
        port(nAddSub    : in std_logic;     -- Control bit for Adder/Subtractor
             i_CLK      : in std_logic;         -- Clock (obviously)
             i_RST      : in std_logic;         -- Reset (obivously)
             i_rs1      : in std_logic_vector(4 downto 0);
             i_rs2      : in std_logic_vector(4 downto 0);
             i_rd       : in std_logic_vector(4 downto 0);
             i_imm      : in std_logic_vector(31 downto 0); -- Need for immediate value. Here we will run it through the extender
             i_ALUSrc   : in std_logic;         -- Controls using rs2 OR imm
             i_memOut   : in std_logic_vector(31 downto 0); -- input to mux from memory
             mem_o_alu  : in std_logic;     -- select for choosing adder or memory output to load into register(s)
             regWrite   : in std_logic;         -- i_dEN : Decoder Enable
         
             o_Data     : out std_logic_vector(31 downto 0);    -- Used to show output of bus mux
             o_rs1      : out std_logic_vector(31 downto 0);
             o_rs2      : out std_logic_vector(31 downto 0);
             o_alu      : out std_logic_vector(31 downto 0) );
    end component;

    component extenders is
        port(i_imm  : in std_logic_vector(11 downto 0);    -- input 12 bit immediate value
             i_ZoS  : in std_logic;                        -- Bit to choose between 
             o_out  : out std_logic_vector(31 downto 0));   -- Output (32-bit) vector
    end component;

    component mem is
        port (clk	: in std_logic;
		      addr  : in std_logic_vector((ADDR_WIDTH-1) downto 0);
		      data  : in std_logic_vector((DATA_WIDTH-1) downto 0);
		      we    : in std_logic;
		      q		: out std_logic_vector((DATA_WIDTH -1) downto 0) );
    end component;

    begin   -- hook up components together
    -- Hook up i_imm to bit extenders

    -- Component => signal/wire/entity
    INST_EXTENDER: extenders
    port map(i_imm  => i_SecImm,            -- take 12 bit input 
             i_ZoS  => ext_Ctrl,            -- Controls Sign or Zero extending
             o_out  => extender_t_adder);   -- Output 32 bits vector from original 12 bit vector


    INST_DATAPATH1: Lab2_DataPath1_for2
    port map(nAddSub    => nAddSub,             -- Controls bit for Adder/Subtractor
             i_CLK      => i_CLK,
             i_RST      => i_RST,
             i_rs1      => i_rs1,
             i_rs2      => i_rs2, 
             i_rd       => i_rd,                
             i_imm      => extender_t_adder,    -- Take in NOW 32 bit immediate from ORIGINALLY 12 bit immediate
             i_ALUSrc   => ALUSrc,              -- Control Bit for using immediate OR rs2
             i_memOut   => memOut,              -- Output from memory into BusMux into registers
             mem_o_alu  => mem_o_alu,           -- Select line for ^^^ BusMux
             regWrite   => regWrite,            -- Enable writing to the registers (decoder enable)
             
             o_Data     => o_Data,
             o_rs1      => o_rs1,
             o_rs2      => o_rs2,
             o_alu      => o_alu);

    INST_MEMORY: mem
    port map(clk    => i_CLK,           -- This is obvious
             addr   => memAddr,        -- Get address
             data   => memData,         -- Connected to RS2 below [Using RS2 to store data in memory]
             we     => i_memWE,         -- Write Enable for RAM
             q      => memOut);         -- Output...
    
    memData     <= o_rs2;   -- Store data comes from rs2
    o_memQ      <= memOut;              -- show the output of memory at address 'addr'
    
    -- Need to cut off bottom 2 bits from input because mem.vhd is word accessible, not byte
    memAddr     <= o_alu(11 downto 2);  -- 10 bits

end architecture;
