-------------------------------------------------------------------------
-- Henry Duwe
-- Jack Dustin
-- Isaiah Pridie
-- Department of Electrical and Computer Engineering
-- Iowa State University of Science and Technology
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

  -- ALU control signals
  signal s_ALUsrc       : std_logic;
  signal s_ALUop        : alu_op_t;

  -- write back to reg signal
  signal s_WBsel        : wb_sel_t; 

  -- branch ctrl signal
  signal s_Branch       : std_logic;

  -- jump ctrl signal
  signal s_jal          : std_logic;
  signal s_jalr         : std_logic;

  -- memory data signed or unsigned ctrl signal
  signal s_MemSign      : std_logic;

  -- register output signals
  signal s_Ors1         : std_logic_vector(N-1 downto 0);
  signal s_Ors2         : std_logic_vector(N-1 downto 0);

  -- extender output signals
  signal s_Oext         : std_logic_vector(N-1 downto 0);

  -- data memory re 
  signal s_DMemRD : std_logic;

  -- ALU output signal
  signal s_ALUOut : std_logic_vector(N-1 downto 0);

  -- ALU 2nd input mux output
  signal s_ALUIn2 : std_logic_vector(N-1 downto 0);
  
 -- ALU contrl signal
 -- ADD signal may/may not force ALU to add for instructions like store, load, jal, jalr
  -- Don't get rid of it! -Isaiah
   signal s_ALUctl    : std_logic_vector(3 downto 0);
   signal s_ALUctlFin : std_logic_vector(3 downto 0); 

 -- LUI control signal
   signal s_isLUI : std_logic;

-- load output after processing by load module (e.g., sign/zero extension, shifting for byte/halfword loads, etc.)
   signal s_LoadOut : std_logic_vector(31 downto 0);


-- AUIPC control signals
  signal s_isAUIPC : std_logic;
  signal s_AUIPCOut : std_logic_vector(N-1 downto 0);
  
   

   signal s_RegWrAddr_c : std_logic_vector(4 downto 0);
   signal s_RegWrData_c : std_logic_vector(N-1 downto 0);
   signal s_RegWr_c     : std_logic;

   signal s_brTaken : std_logic;
   signal s_Fetchsrc : std_logic_vector(1 downto 0); -- for PC Muxes: 00=PC+4, 01=PC+imm, 10=jalr target, 11=default to PC+4 (for now)
   signal s_PC4 : std_logic_vector(N-1 downto 0);

   signal s_JalrTarget : std_logic_vector(N-1 downto 0);


   
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
  port(
    i_CLK    : in  std_logic;
    i_RST_PC : in  std_logic;
    i_imm    : in  std_logic_vector(31 downto 0);
    --c_PC_add : in  std_logic;
    i_alu      : in  std_logic_vector(31 downto 0);
    c_PC_sel : in  std_logic_vector(1 downto 0);
    o_PC4    : out std_logic_vector(31 downto 0);
    o_PC     : out std_logic_vector(31 downto 0)
  );
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
          is_lui     : out std_logic;
          is_auipc   : out std_logic;
          alu_op    : out alu_op_t;
          mem_sign  : out std_logic   -- for loads: 1=signed, 0=unsigned
        
  );
  end component;

  component addSub is
    generic (N : integer := 32);    -- use 32 for now. Value not specified in Lab Doc
    port (  i_Da        :   in std_logic_vector(N-1 downto 0);
            i_Db        :   in std_logic_vector(N-1 downto 0);
            nAdd_Sub    :   in std_logic;   -- used as control/carry
            o_Sum       :   out std_logic_vector(N-1 downto 0);
            o_Car       :   out std_logic);  -- used for last carry output
    
  end component;

  component reg_file is
    
    port(
          i_RS1   : in std_logic_vector(4 downto 0);   -- 5 bit bus    -- [19:15]
          i_RS2   : in std_logic_vector(4 downto 0);   -- 5 bit bus    -- [24:20]
          o_rs1   : out std_logic_vector(31 downto 0);    -- Result of RS1 input
          o_rs2   : out std_logic_vector(31 downto 0);    -- Result of RS2 input
          i_rd    : in std_logic_vector(4 downto 0);   -- 5 but bus    -- [11:7]
          i_dEN   : in std_logic;     -- Decoder EN bit
          i_RST   : in std_logic;     -- RESET bit
          i_CLK   : in std_logic;     -- Clock Signal for register
          i_DATA  : in std_logic_vector(31 downto 0));  -- 32 bit bus   -- Register Data Input
  end component;

  component imm_gen is
    port(
      i_instr : in  std_logic_vector(31 downto 0);
      o_imm   : out std_logic_vector(31 downto 0)
    );
  end component;

  component mux2t1_N is
    generic (N : integer);
    port(
          i_D0   : in std_logic_vector(31 downto 0);
          i_D1   : in std_logic_vector(31 downto 0);
          i_S  : in std_logic;
          o_O  : out std_logic_vector(31 downto 0));
  end component;

  component proj01_ALU is
    
    port(
          i_A     : in std_logic_vector((DATA_WIDTH - 1) downto 0);
          i_B     : in std_logic_vector((DATA_WIDTH - 1) downto 0);
          i_ALUctl : in std_logic_vector(3 downto 0);   -- control bus for ALU operation (e.g., add, sub, and, or, etc.)
          o_ALUout    : out std_logic_vector((DATA_WIDTH - 1) downto 0); -- ALU output determined by control signal
          o_branchOut: out std_logic
    ); 
  end component;

  component andg2 is
    port(i_A          : in std_logic;
       i_B          : in std_logic;
       o_F          : out std_logic);
  end component;

  component proj01_LOAD is
    port(
         i_memVal       : in  std_logic_vector(31 downto 0);    
         c_addr_2bit    : in  std_logic_vector(1  downto 0);    -- Lower 2 bits of DMEM addr
         c_funct3       : in  std_logic_vector(2  downto 0);    
         o_LoadOut      : out std_logic_vector(31 downto 0));
  end component;
  

begin
  s_Ovfl <= '0'; -- RISC-V does not have hardware overflow detection.
 
  oALUOut     <= s_ALUOut;             -- drive top-level output

   s_DMemAddr <= s_ALUOut;   -- effective address from ALU
   s_DMemData <= s_Ors2;     -- store data from rs2
 
-- WFI detect (SYSTEM opcode 1110011, funct3=000, imm12=0x105)

s_Halt <= '1' when (iRST='0' and iInstLD='0' and
                    s_Inst(6 downto 0)    = "1110011" and
                    s_Inst(14 downto 12) = "000"     and
                    s_Inst(31 downto 20) = x"105")
          else '0';


s_RegWrAddr <= s_Inst(11 downto 7);
s_RegWrData <= s_Oext      when s_isLUI='1' else
                s_AUIPCOut  when s_isAUIPC='1' else
                s_PC4        when s_WBsel = WB_PC4 else
                s_LoadOut   when s_WBsel = WB_MEM else
                s_ALUOut;




-- Gate register writes off during WFI (avoid std_logic and/not operator issues)

  -- with s_ALUop select
  -- s_ALUctl <=
  --   "0000" when ALU_ADD,  -- add / addi / lw / sw address calc
  --   "0001" when ALU_SUB,  -- sub
  --   "0100" when ALU_SLL,  -- shift left logical
  --   "0010" when ALU_SLT,  -- set less than
  --   --""     when ALU_SLTU,
  --   "1000" when ALU_XOR,  -- xor
  --   "1010" when ALU_SRL,  -- shift right logical
  --   "1011" when ALU_SRA,  -- shift right arithmetic
  --   "1100" when ALU_OR,   -- or
  --   "1110" when ALU_AND,  -- and
  --   "0000" when others;
  -- proj01_ALU expects i_ALUctl bits to match instruction fields:
-- (3)=funct3(1)=instr(13), (2)=funct3(2)=instr(14), (1)=funct3(0)=instr(12), (0)=funct7(5)=instr(30)

  s_ALUctl(3) <= s_Inst(13);
  s_ALUctl(2) <= s_Inst(14);
  s_ALUctl(1) <= s_Inst(12);

  -- Only use instr(30) for SUB (R-type funct7=0100000) and for SRAI/SRA (shift-right arithmetic)
  s_ALUctl(0) <= s_Inst(30) when (s_Inst(6 downto 0)=OP_RTYPE) or
                              (s_Inst(6 downto 0)=OP_ITYPE and s_Inst(14 downto 12)="101")
                else '0';

   -- Assign new ALU funct 3 bits to [funct3 * (B_ctrl || OpCode(4))]
  -- Forces Adder/Sub output from ALU when not doing other ALU instructions
      -- Yes, it is needed. For addressing (load/store), and (blt/bge/bltu/bgeu), and jal/jalr
  s_ALUctlFin(3) <= s_ALUctl(3) and (s_Branch or s_Inst(4));
  s_ALUctlFin(2) <= s_ALUctl(2) and (s_Branch or s_Inst(4));
  s_ALUctlFin(1) <= s_ALUctl(1) and (s_Branch or s_Inst(4));

  -- Force Subtraction (or allow adding) for branching (blt) 
  -- 
  s_ALUctlFin(0) <= (s_ALUctl(0) and s_Inst(4)) or s_Branch;

  
  s_JalrTarget <= s_ALUOut(31 downto 1) & '0'; -- For jalr, target is rs1+imm (also output of ALU with correct control signals)

  s_Fetchsrc(1) <= s_jalr;
  s_Fetchsrc(0) <= s_jal or s_jalr or (s_Branch and s_brTaken);
    
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
  port map(
    i_CLK    => iCLK,
    i_RST_PC => iRST,
    i_imm    => s_Oext,
    i_alu    => s_JalrTarget,
    c_PC_sel => s_Fetchsrc,
    o_PC     => s_PC,
    o_PC4    => s_PC4);
  CDec: ctrl_decoder
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(
              instr     => s_Inst,
              reg_we    => s_RegWr,
              alu_src   => s_ALUsrc,
              mem_we    => s_DMemWr,
              mem_re    => s_DMemRD,
              wb_sel    => s_WBsel,
              is_branch => s_Branch,
              is_jal    => s_jal,
              is_jalr   => s_jalr,
              is_lui    => s_isLUI,
              is_auipc  => s_isAUIPC,
              alu_op    => s_ALUop
              -- mem_size  => s_memsize
             );

  Rfile: reg_file
    
    port map(
              i_RS1   => s_Inst(19 downto 15),
              i_RS2   => s_Inst(24 downto 20),
              o_rs1   => s_Ors1,
              o_rs2   => s_Ors2,
              i_rd    => s_RegWrAddr_c, -- s_Inst(11 downto 7)
              i_dEN   => s_RegWr,
              i_RST   => iRST,
              i_CLK   => iCLK,
              i_DATA  => s_RegWrData_c
             );
  
  Imm0: imm_gen
  port map(
    i_instr => s_Inst,
    o_imm   => s_Oext
  );

  AUIPC_ADD: addSub
  port map(
    i_Da     => s_PC,
    i_Db     => s_Oext,      -- imm_gen must output immU for AUIPC
    nAdd_Sub   => '0',         -- add
    o_Sum   => s_AUIPCOut,
    o_Car  => open
  );
  
  

  
  
  Mux_ALUSrc: mux2t1_N
  generic map(N => N)
  port map(
    i_D0 => s_Ors2,
    i_D1 => s_Oext,
    i_S  => s_ALUsrc,
    o_O  => s_ALUIn2
  );


 


  ALU0: proj01_ALU
  port map(
    i_A     => s_Ors1, -- rs1
    i_B     => s_ALUIn2, -- output of ALU input mux
    i_ALUctl => s_ALUctlFin, -- control signal from control decoder for ALU operation
    o_ALUout    => s_ALUOut,  -- TODO: connect this to the output of your ALU and to the oALUOut output port of the processor
    o_branchOut => s_brTaken);



  -- AND0: andg2
  --   port map (
  --     i_A  => s_Branch,
  --     i_B  => s_brTaken,
  --     o_F  => s_Fetchsrc);

-- implement load functionality

  LOAD0: proj01_LOAD
    port map(
      i_memVal    => s_DMemOut,
      c_addr_2bit => s_ALUOut(1 downto 0),  -- Need ALU out b/c immediate address offset
      c_funct3    => s_Inst(14 downto 12),
      o_LoadOut   => s_LoadOut
    ); -- connect to data input of regfile write data (and also to your ALU output mux if you have one for load instructions)

  
-- tie to memory
-- imm generator for load offsets
-- implement store functionality
-- implement branches and jumps (PC update logic)

end structure;