-------------------------------------------------------------------------
-- Henry Duwe
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- RISCV_Processor.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains a skeleton of a RISCV_Processor  
-- implementation.

-- 01/29/2019 by H3::Design created.
-- 04/10/2025 by AP::Coverted to RISC-V.
-- 02/19/2026 by H3::Renamed PC and handled OVFL
-------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.RISCV_types.all;

entity RISCV_Processor is
  generic(N : integer := DATA_WIDTH);
  port(iCLK            : in std_logic;
       iRST            : in std_logic;
       iInstLd         : in std_logic;
       iInstAddr       : in std_logic_vector(N-1 downto 0);
       iInstExt        : in std_logic_vector(N-1 downto 0);
       oALUOut         : out std_logic_vector(N-1 downto 0)); -- TODO: Hook this up to the output of the ALU. It is important for synthesis that you have this output that can effectively be impacted by all other components so they are not optimized away.

end  RISCV_Processor;


architecture structure of RISCV_Processor is

  -- Required data memory signals
  signal s_DMemWr       : std_logic; -- TODO: use this signal as the final active high data memory write enable signal
  signal s_DMemAddr     : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory address input
  signal s_DMemData     : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory data input
  signal s_DMemOut      : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the data memory output
 
  -- Required register file signals 
  signal s_RegWr        : std_logic; -- TODO: use this signal as the final active high write enable input to the register file
  signal s_RegWrAddr    : std_logic_vector(4 downto 0); -- TODO: use this signal as the final destination register address input
  signal s_RegWrData    : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory data input

  -- Required instruction memory signals
  signal s_IMemAddr     : std_logic_vector(N-1 downto 0); -- Do not assign this signal, assign to s_PC instead
  signal s_PC : std_logic_vector(N-1 downto 0); -- TODO: use this signal as your intended final instruction memory address input.
  signal s_Inst         : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the instruction signal 

  -- Required halt signal -- for simulation
  signal s_Halt         : std_logic;  -- TODO: this signal indicates to the simulation that intended program execution has completed. (Use WFI with Opcode: 111 0011 func3: 000 and func12: 000100000101 -- func12 is imm field from I-format)

  -- Required overflow signal -- for overflow exception detection
  signal s_Ovfl         : std_logic;  -- this signal indicates an overflow exception would have been initiated

  component mem is
    generic(ADDR_WIDTH : integer;
            DATA_WIDTH : integer);
    port(
          clk          : in std_logic;
          addr         : in std_logic_vector((ADDR_WIDTH-1) downto 0);
          data         : in std_logic_vector((DATA_WIDTH-1) downto 0);
          we           : in std_logic := '1';
          q            : out std_logic_vector((DATA_WIDTH -1) downto 0));
    end component;

  -- TODO: You may add any additional signals or components your implementation 
  --       requires below this comment

  component proj1_fetch is
    generic(ADDR_WIDTH : integer;
            DATA_WIDTH : integer);
    port(i_CLK      : in std_logic;
         i_RST_PC   : in std_logic;     -- Need different reset* (this one); We need to reset register to 0x0040.0000 not 0x0000.0000
         i_imm      : in std_logic_vector((DATA_WIDTH - 1) downto 0);     -- imm AFTER SIGN-EXTENDING AND MUXING
         c_PC_add   : in std_logic;                         -- Control bit for choosing between "+4" and "+imm"
         o_PC       : out std_logic_vector((DATA_WIDTH - 1) downto 0) );  -- Output from PC register to Instruction memory)
  end component;

  component ctrl_decoder is
    generic(ADDR_WIDTH : integer;
            DATA_WIDTH : integer);
    port(
          instr     : in  std_logic_vector((DATA_WIDTH - 1) downto 0);

          reg_we    : out std_logic;
          alu_src   : out std_logic;   -- 0=rs2, 1=imm
          mem_we    : out std_logic;
          mem_re    : out std_logic;
          wb_sel    : out wb_sel_t; 

          is_branch : out std_logic;
          is_jal    : out std_logic;
          is_jalr   : out std_logic;

          alu_op    : out alu_op_t;
          mem_sign  : out std_logic   -- for loads: 1=signed, 0=unsigned
        
  );
  end component;

  component reg_file is
    generic(ADDR_WIDTH : integer;
            DATA_WIDTH : integer);
    port(
          i_RS1   : in std_logic_vector((ADDR_WIDTH - 1) downto 0);   -- 5 bit bus    -- [19:15]
          i_RS2   : in std_logic_vector((ADDR_WIDTH - 1) downto 0);   -- 5 bit bus    -- [24:20]
          o_rs1   : out std_logic_vector((DATA_WIDTH - 1) downto 0);    -- Result of RS1 input
          o_rs2   : out std_logic_vector((DATA_WIDTH - 1) downto 0);    -- Result of RS2 input
          i_rd    : in std_logic_vector((ADDR_WIDTH - 1) downto 0);   -- 5 but bus    -- [11:7]
          i_dEN   : in std_logic;     -- Decoder EN bit
          i_RST   : in std_logic;     -- RESET bit
          i_CLK   : in std_logic;     -- Clock Signal for register
          i_DATA  : in std_logic_vector((DATA_WIDTH - 1) downto 0));  -- 32 bit bus   -- Register Data Input
  end component;

  component extenders is 
    generic(DATA_WIDTH : integer);
    port(
         i_imm  : in std_logic_vector(11 downto 0);    -- input 12 bit immediate value
         i_ZoS  : in std_logic;                        -- Bit to choose between 
         o_out  : out std_logic_vector((DATA_WIDTH - 1) downto 0));   -- Output (32-bit) vector
  end component;

  component addSub is
    generic(DATA_WIDTH : integer);
    port (  i_Da        :   in std_logic_vector(DATA_WIDTH-1 downto 0);
            i_Db        :   in std_logic_vector(DATA_WIDTH-1 downto 0);
            nAdd_Sub    :   in std_logic;   -- used as control/carry
            o_Sum       :   out std_logic_vector(DATA_WIDTH-1 downto 0);
            o_Car       :   out std_logic);  -- used for last carry output
  end component;

  component MySecondDataPath is
    generic(ADDR_WIDTH : integer;
            DATA_WIDTH : integer);
     port(nAddSub    : in std_logic;     -- Control bit for Adder/Subtractor
             i_CLK      : in std_logic;         -- Clock (obviously)
             i_RST      : in std_logic;         -- Reset (obivously)
             i_rs1      : in std_logic_vector((ADDR_WIDTH - 1) downto 0);
             i_rs2      : in std_logic_vector((ADDR_WIDTH - 1) downto 0);
             i_rd       : in std_logic_vector((ADDR_WIDTH - 1) downto 0);
             i_imm      : in std_logic_vector((DATA_WIDTH - 1) downto 0); -- Need for immediate value. Here we will run it through the extender
             i_ALUSrc   : in std_logic;         -- Controls using rs2 OR imm
             i_memOut   : in std_logic_vector((DATA_WIDTH - 1) downto 0); -- input to mux from memory
             mem_o_alu  : in std_logic;     -- select for choosing adder or memory output to load into register(s)
             regWrite   : in std_logic;         -- i_dEN : Decoder Enable
         
             o_Data     : out std_logic_vector((DATA_WIDTH - 1) downto 0);    -- Used to show output of bus mux
             o_rs1      : out std_logic_vector((DATA_WIDTH - 1) downto 0);
             o_rs2      : out std_logic_vector((DATA_WIDTH - 1) downto 0);
             o_alu      : out std_logic_vector((DATA_WIDTH - 1) downto 0) );
  end component;

begin
  s_Ovfl <= '0'; -- RISC-V does not have hardware overflow detection.
  -- TODO: This is required to be your final input to your instruction memory. This provides a feasible method to externally load the memory module which means that the synthesis tool must assume it knows nothing about the values stored in the instruction memory. If this is not included, much, if not all of the design is optimized out because the synthesis tool will believe the memory to be all zeros.
  with iInstLd select
    s_IMemAddr <= s_PC when '0',
      iInstAddr when others;


  IMem: mem
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(clk  => iCLK,
             addr => s_IMemAddr(11 downto 2),
             data => iInstExt,
             we   => iInstLd,
             q    => s_Inst);
  
  DMem: mem
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(clk  => iCLK,
             addr => s_DMemAddr(11 downto 2),
             data => s_DMemData,
             we   => s_DMemWr,
             q    => s_DMemOut);

  -- TODO: Ensure that s_Halt is connected to an output control signal produced from decoding the Halt instruction (Opcode: 01 0100)

  -- TODO: Implement the rest of your processor below this comment! 

  IFetch: proj1_fetch
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(
              i_CLK   
              i_RST_PC
              i_imm   
              c_PC_add
              o_PC  
             );
  CDec: ctrl_decoder
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(
              instr    
              reg_we   
              alu_src  
              mem_we   
              mem_re   
              wb_sel   
              is_branch
              is_jal   
              is_jalr  
              alu_op   
              mem_sign  
             );
  Rfile: reg_file
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(
              i_RS1 
              i_RS2 
              o_rs1 
              o_rs2 
              i_rd  
              i_dEN 
              i_RST 
              i_CLK 
              i_DATA
             );
  Ext: extenders
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(
              i_imm
              i_ZoS
              o_out
             );
  LAddsub: addSub
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(
              i_Da    
              i_Db    
              nAdd_Sub
              o_Sum   
              o_Car   
             );
  DataP: MySecondDataPath
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(
              i_CLK    
              i_RST    
              i_rs1    
              i_rs2    
              i_rd     
              i_imm    
              i_ALUSrc 
              i_memOut 
              mem_o_alu
              regWrite 
              o_Data   
              o_rs1    
              o_rs2    
              o_alu    
             );
end structure;