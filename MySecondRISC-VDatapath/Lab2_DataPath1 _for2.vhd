-- Isaiah Pridie
-- CprE 3810 Lab2 Part 4(d)
-- Start Date: 2.18.2026,   1:19 AM 
-- Same as Lab2_DataPath1, except with a mux for choosing between memory and adder output

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.mux_32t1_package.all; -- import package from word folder

entity Lab2_DataPath1_for2 is
    port(nAddSub    : in std_logic;     -- Control bit for Adder/Subtractor
         i_CLK      : in std_logic;     -- Clock (obviously)
         i_RST      : in std_logic;     -- Reset (obivously)
         i_rs1      : in std_logic_vector(4 downto 0);
         i_rs2      : in std_logic_vector(4 downto 0);
         i_rd       : in std_logic_vector(4 downto 0);
         i_imm      : in std_logic_vector(31 downto 0); -- Need for immediate value. This is AFTER the bit extender
         i_ALUSrc   : in std_logic;     -- Controls using rs2 OR imm
         i_memOut   : in std_logic_vector(31 downto 0); -- input to mux from memory
         mem_o_alu  : in std_logic;     -- select for choosing adder or memory output to load into register(s)
         regWrite   : in std_logic;     -- i_dEN : Decoder Enable
         
         o_Data     : out std_logic_vector(31 downto 0);    -- Use to see output of busmux into registers
         o_rs1      : out std_logic_vector(31 downto 0);
         o_rs2      : out std_logic_vector(31 downto 0);
         o_alu      : out std_logic_vector(31 downto 0) 
        );
end Lab2_DataPath1_for2;

architecture structural of lab2_DataPath1_for2 is

    -- Wire/Signal declarations:
    signal rs1_t_ALUa       : std_logic_vector(31 downto 0);    -- rs1 to ADDER input A
    signal rs2_t_busMux     : std_logic_vector(31 downto 0);    -- rs2 to busMux w/ imm
    signal busMux_t_ALUb    : std_logic_vector(31 downto 0);    -- busMux to ADDER input B
    signal oAdd_t_iData     : std_logic_vector(31 downto 0);    -- ADDER output to i_DATA
    signal oCarryDebug      : std_logic;                        -- Don't know rn what else to do with final carry out
    signal i_Data           : std_logic_vector(31 downto 0);    -- Carries output of memory or alu mux to registers

    component addSub is
        port(i_Da       :   in std_logic_vector(31 downto 0);
             i_Db       :   in std_logic_vector(31 downto 0);
             nAdd_Sub   :   in std_logic;   -- used as control/carry
             o_Sum      :   out std_logic_vector(31 downto 0);
             o_Car      :   out std_logic);  -- used for last carry output
    end component;

    component busMux_2t1 is
        port(i_dZero  : in std_logic_vector(31 downto 0);
             i_dOne   : in std_logic_vector(31 downto 0);
             ALUSrc   : in std_logic; -- select line
             o_dOUT   : out std_logic_vector(31 downto 0));
    end component;

    component reg_file is
        port(i_RS1   : in std_logic_vector(4 downto 0);   -- 5 bit bus    -- [19:15]
             i_RS2   : in std_logic_vector(4 downto 0);   -- 5 bit bus    -- [24:20]
             o_rs1   : out std_logic_vector(31 downto 0);    -- Result of RS1 input
             o_rs2   : out std_logic_vector(31 downto 0);    -- Result of RS2 input
             i_rd    : in std_logic_vector(4 downto 0);   -- 5 but bus    -- [11:7]
             i_dEN   : in std_logic;     -- Decoder EN bit
             i_RST   : in std_logic;     -- RESET bit
             i_CLK   : in std_logic;     -- Clock Signal for register
             i_DATA  : in std_logic_vector(31 downto 0));  -- 32 bit bus   -- Register Data Input
    end component;

    begin
    -- Start building circuit
        -- Left = Components. Right = entity AND signals

    -- Reg file port map
    INST_REG_FILE: reg_file
    port map(i_RS1  => i_rs1,       -- i_RS1 goes to entity i_rs1
             i_RS2  => i_rs2,       -- i_RS2 goes to entity i_rs2
             o_rs1  => rs1_t_ALUa,  -- o_rs1 goes to input A of ADDER
             o_rs2  => rs2_t_busMux,    -- o_rs2 goes to input 0 of busMux
             i_rd   => i_rd,        -- i_rd goes to entity i_rd
             i_dEN  => regWrite,    -- digital enable for decoder is now called regWrite
             i_RST  => i_RST,       
             i_CLK  => i_CLK,   
             i_DATA => i_Data);   -- input Data gets input from 2t1 bus mux
    -- oAdd_t_iData
    -- Mux Port Map
    INST_BUSMUX_2t1: busMux_2t1
    port map(i_dZero => rs2_t_busMux,   -- rs2 goes to 0_input of busMux
             i_dOne  => i_imm,               -- imm goes to 1_input of busMux
             ALUSrc  => i_ALUSrc,            -- ALUSrc is select line
             o_dOUT  => busMux_t_ALUb);       -- busMux output goes to adder, input B

    INST_ADDERSUB: addSub
    port map(i_Da       => rs1_t_ALUa,
             i_Db       => busMux_t_ALUb,
             nAdd_Sub   => nAddSub,
             o_Sum      => oAdd_t_iData,
             o_Car      => oCarryDebug);


    INST_BUSMUS_2t1_2: busMux_2t1
    -- Ports on bus_mux have bad names. This MUX was originally made only for choosing between rs2 and immediate value
    port map(i_dZero    => oAdd_t_iData,    -- 0 input will be ALU output
             i_dOne     => i_memOut,        -- 1 input will be memory output
             ALUSrc     => mem_o_alu,       -- Select line
             o_dOUT     => i_Data);         -- Output of mux goes back to registers


    o_rs1   <= rs1_t_ALUa;      -- Set o_rs1 output to o_rs1 
    o_rs2   <= rs2_t_busMux;    -- Set o_rs2 output to o_rs2 (WOAH. Craziest thing)
    o_alu   <= oAdd_t_iData;
    o_Data  <= i_Data;

end architecture;