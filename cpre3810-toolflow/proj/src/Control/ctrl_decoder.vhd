library ieee;
use ieee.std_logic_1164.all;
use work.RISCV_types.all;

entity ctrl_decoder is
  generic(
    ADDR_WIDTH : integer;
    DATA_WIDTH : integer
  );
  port(
    instr     : in  std_logic_vector(31 downto 0);

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
    -- mem_size  : out mem_size_t
  );
end entity;

architecture dataflow of ctrl_decoder is
  signal opcode : std_logic_vector(6 downto 0);
  signal funct3 : std_logic_vector(2 downto 0);
  signal funct7 : std_logic_vector(6 downto 0);

  --testing declarations delete incrementally
  

  -- opcode class flags
  signal is_rtype, is_itype, is_lui, is_load, is_store, is_branch_op, is_jal_op, is_jalr_op: std_logic; --, , , is_b, , is_u_auipc : std_logic;
  

  -- ALU op candidates
  signal alu_r : alu_op_t;
  -- signal alu_r_m    : alu_op_t;
  signal alu_i      : alu_op_t;
  signal alu_ldst   : alu_op_t;
  signal alu_u      : alu_op_t;

  
  
begin

  is_branch <= is_branch_op;
  is_jal    <= is_jal_op;
  is_jalr   <= is_jalr_op;



  opcode <= instr(6 downto 0);
  funct3 <= instr(14 downto 12);
  funct7 <= instr(31 downto 25);
  
  -- classify opcodes
  is_rtype   <= '1' when opcode = OP_RTYPE  else '0';
  is_itype   <= '1' when opcode = OP_ITYPE  else '0';
  is_load    <= '1' when opcode = OP_LOAD   else '0';
  is_store   <= '1' when opcode = OP_STORE  else '0';
  is_b       <= '1' when opcode = OP_BRANCH else '0';

  is_jal_op     <= '1' when opcode = OP_JAL    else '0';
  is_jalr_op    <= '1' when opcode = OP_JALR   else '0';

  is_lui   <= '1' when opcode = OP_LUI    else '0';
  -- is_auipc <= '1' when opcode = OP_AUIPC  else '0';


  reg_we  <= '1' when (is_rtype='1' or is_itype='1' or is_load='1' or is_jal_op='1' or is_jalr_op='1' or is_lui='1') -- or is_auipc
              else '0';

  --reg_we <= '1' when (is_rtype='1' or is_itype='1' or is_lui='1' or is_load='1') else '0';

  alu_src <= '1' when (is_itype='1'or is_load='1' or is_store='1' or is_jalr_op='1') -- or is_u_auipc='1')
             else '0';

  mem_we  <= '1' when is_store='1' else '0';
  mem_re  <= '1' when is_load='1'  else '0';
  
  
  mem_sign  <= '1';

  -- is_branch_op <= is_b;

  -- Writeback select
   wb_sel <= WB_MEM when is_load='1' else
            WB_PC4 when (is_jal_op='1' or is_jalr_op='1') else
            WB_ALU;

    -- wb_sel <= WB_MEM when is_load='1' else
    --           WB_ALU;

  ---------------------------------------------------------------------------
  -- mem_size + mem_sign (loads/stores)
  ---------------------------------------------------------------------------
  -- mem_size <=
  --     MS_B when ((is_load='1' or is_store='1') and funct3="000") else
  --     MS_H when ((is_load='1' or is_store='1') and funct3="001") else
  --     MS_W when ((is_load='1' or is_store='1') and funct3="010") else
  --     --load only
  --     MS_B when (is_load='1' and funct3="100") else
  --     MS_H when (is_load='1' and funct3="101") else
  --     MS_W;
      
  -- mem_sign <=
  --   '0' when (is_load='1' and (funct3="100" or funct3="101")) else  -- lbu/lhu
  --   '1';                                                            -- lb/lh/lw (and don't-care otherwise)
   
  ---------------------------------------------------------------------------
  -- ALU decode (dataflow)
  ---------------------------------------------------------------------------

  -- R-type base (non-M extension)
  alu_r <=
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
    -- ALU_SLT  when funct3="010" else  -- slti
    -- ALU_SLTU when funct3="011" else  -- sltiu
    ALU_XOR  when funct3="100" else  -- xori
    ALU_OR   when funct3="110" else  -- ori
    ALU_AND  when funct3="111" else  -- andi
    ALU_SLL  when funct3="001" else  -- slli
    ALU_SRA  when (funct3="101" and funct7="0100000") else -- srai
    ALU_SRL  when funct3="101" else  -- srli
    ALU_ADD;

  -- -- Loads/stores/jalr use address add
  alu_ldst <= ALU_ADD;

  -- -- U-type
  alu_u <= ALU_ADD;                           -- AUIPC: rd = pc + imm_u (A=pc in top-level)

  

  is_branch <= is_b;

  alu_op <= alu_r when is_rtype='1' else
          alu_i when is_itype='1' else
          ALU_ADD when is_load ='1' else
          ALU_SUB when is_b = '1' else
          ALU_ADD
          ;

end architecture;