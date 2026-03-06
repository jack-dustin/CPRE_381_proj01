-- control.vhd (DATAFLOW/STRUCTURAL ONLY: no processes)
library ieee;
use ieee.std_logic_1164.all;
use work.rv32_pkg.all;

entity control is
  port(
    instr     : in  std_logic_vector(31 downto 0);

    o_reg_we    : out std_logic;
    o_alu_src   : out std_logic;   -- 0=rs2, 1=imm
    o_mem_we    : out std_logic;
    o_mem_re    : out std_logic;
    o_memtreg    : out wb_sel_t; 

    o_is_branch : out std_logic;
    o_is_jal    : out std_logic;
    o_is_jalr   : out std_logic;

    o_alu_op    : out alu_op_t;   -- I dont know what this is
    o_mem_sign  : out std_logic;   -- for loads: 1=signed, 0=unsigned
  );
end entity;

architecture dataflow of control is
  signal opcode : std_logic_vector(6 downto 0);
  signal funct3 : std_logic_vector(2 downto 0);
  signal funct7 : std_logic_vector(6 downto 0);

  -- opcode class flags
  signal is_rtype, is_itype, is_load, is_store, is_b, is_u_lui, is_u_auipc : std_logic;
  signal is_mext : std_logic; --I don't know what this is

  -- ALU operations
  type alu_op_t is (
    ALU_ADD, ALU_SUB,
    ALU_AND, ALU_OR, ALU_XOR,
    ALU_SLT, ALU_SLTU,
    ALU_SLL, ALU_SRL, ALU_SRA,
    ALU_COPY_B,
  );

  -- ALU op candidates
  signal alu_r_base : alu_op_t;
  signal alu_r_m    : alu_op_t;
  signal alu_i      : alu_op_t;
  signal alu_ldst   : alu_op_t;
  signal alu_u      : alu_op_t;

  begin
    opcode <= instr(6 downto 0);
    funct3 <= instr(14 downto 12);
    funct7 <= instr(31 downto 25);

  -- opcode classification
  -- rtype 0110011
  -- itype 0010011
  -- load 0000011
  -- store 0100011
  -- branch 1100011
  -- lui 0110111
  -- auipc 0010111
  -- jalr 1100111
  -- jal 1101111

  constant OP_RTYPE  : std_logic_vector(6 downto 0) := "0110011";
  constant OP_ITYPE  : std_logic_vector(6 downto 0) := "0010011";
  constant OP_LOAD   : std_logic_vector(6 downto 0) := "0000011";
  constant OP_STORE  : std_logic_vector(6 downto 0) := "0100011";
  constant OP_BRANCH : std_logic_vector(6 downto 0) := "1100011";
  constant OP_JAL    : std_logic_vector(6 downto 0) := "1101111";
  constant OP_JALR   : std_logic_vector(6 downto 0) := "1100111";
  constant OP_LUI    : std_logic_vector(6 downto 0) := "0110111";
  constant OP_AUIPC  : std_logic_vector(6 downto 0) := "0010111";
  

  -- classify opcodes
  is_rtype   <= '1' when opcode = OP_RTYPE  else '0';
  is_itype   <= '1' when opcode = OP_ITYPE  else '0';
  is_load    <= '1' when opcode = OP_LOAD   else '0';
  is_store   <= '1' when opcode = OP_STORE  else '0';
  is_b       <= '1' when opcode = OP_BRANCH else '0';

  is_jal     <= '1' when opcode = OP_JAL    else '0';
  is_jalr    <= '1' when opcode = OP_JALR   else '0';

  is_u_lui   <= '1' when opcode = OP_LUI    else '0';
  is_u_auipc <= '1' when opcode = OP_AUIPC  else '0';

  -- dataflow control outputs
  --write back to a register
  reg_we  <= '1' when (is_rtype='1' or is_itype='1' or is_load='1' or is_jal='1' or is_jalr='1' or is_u_lui='1' or is_u_auipc='1')
             else '0';
  -- immediate or register operation
  alu_src <= '1' when (is_itype='1' or is_load='1' or is_store='1' or is_jalr='1' or is_u_lui='1' or is_u_auipc='1')
             else '0';
  
  --load and store enable
  mem_we  <= '1' when is_store='1' else '0';
  mem_re  <= '1' when is_load='1'  else '0';

  is_branch <= is_b;

  -- Writeback select --TODO
  memtreg <= WB_MEM when is_load='1' else
            WB_PC4 when (is_jal='1' or is_jalr='1') else
            WB_ALU;

  -- R-type base
  alu_r_base <=
    -- add/sub
    ALU_SUB when (funct3="000" and funct7="0100000") else
    ALU_ADD when (funct3="000") else
    -- shifts/logic/compares
    ALU_SLL  when (funct3="001") else
    ALU_SLT  when (funct3="010") else
    ALU_SLTU when (funct3="011") else
    ALU_XOR  when (funct3="100") else
    ALU_SRA  when (funct3="101" and funct7="0100000") else
    ALU_SRL  when (funct3="101") else
    ALU_OR   when (funct3="110") else
    ALU_AND  when (funct3="111") else
    ALU_ADD;

    -- I-type ALU ops
  alu_i <=
    ALU_ADD  when funct3="000" else  -- addi
    ALU_SLT  when funct3="010" else  -- slti
    ALU_SLTU when funct3="011" else  -- sltiu
    ALU_XOR  when funct3="100" else  -- xori
    ALU_OR   when funct3="110" else  -- ori
    ALU_AND  when funct3="111" else  -- andi
    ALU_SLL  when funct3="001" else  -- slli
    ALU_SRA  when (funct3="101" and funct7="0100000") else -- srai
    ALU_SRL  when funct3="101" else  -- srli
    ALU_ADD;

    -- Loads/stores/jalr use address add
  alu_ldst <= ALU_ADD;

  -- Final ALU op select by opcode class
  alu_op <=
    alu_r_m    when (is_mext='1') else
    alu_r_base when (is_rtype='1') else
    alu_i      when (is_itype='1') else
    alu_ldst   when (is_load='1' or is_store='1' or is_jalr='1') else
    alu_u      when (is_u_lui='1' or is_u_auipc='1') else
    ALU_ADD;

  end architecture;
