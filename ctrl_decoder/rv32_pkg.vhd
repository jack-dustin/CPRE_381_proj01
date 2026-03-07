library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package rv32_pkg is
  subtype u32 is std_logic_vector(31 downto 0);
  subtype u5  is std_logic_vector(4 downto 0);

  -- Opcodes
  constant OP_RTYPE  : std_logic_vector(6 downto 0) := "0110011";
  constant OP_ITYPE  : std_logic_vector(6 downto 0) := "0010011";
  constant OP_LOAD   : std_logic_vector(6 downto 0) := "0000011";
  constant OP_STORE  : std_logic_vector(6 downto 0) := "0100011";
  constant OP_BRANCH : std_logic_vector(6 downto 0) := "1100011";
  constant OP_JAL    : std_logic_vector(6 downto 0) := "1101111";
  constant OP_JALR   : std_logic_vector(6 downto 0) := "1100111";
  constant OP_LUI    : std_logic_vector(6 downto 0) := "0110111";
  constant OP_AUIPC  : std_logic_vector(6 downto 0) := "0010111";

  -- ALU ops
  type alu_op_t is (
    ALU_ADD, ALU_SUB,
    ALU_AND, ALU_OR, ALU_XOR,
    ALU_SLT, ALU_SLTU,
    ALU_SLL, ALU_SRL, ALU_SRA,
    ALU_COPY_B,
    -- M extension
    ALU_MUL, ALU_MULH, ALU_MULHSU, ALU_MULHU,
    ALU_DIV, ALU_DIVU, ALU_REM, ALU_REMU
  );

  -- Writeback select
  type wb_sel_t is (WB_ALU, WB_MEM, WB_PC4);


end package;