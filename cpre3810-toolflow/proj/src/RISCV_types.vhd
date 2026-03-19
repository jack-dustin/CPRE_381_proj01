-------------------------------------------------------------------------
-- Author: Braedon Giblin
-- Date: 2022.02.12
-- Files: RISCV_types.vhd
-------------------------------------------------------------------------
-- Description: This file contains a skeleton for some types that 381 students
-- may want to use. This file is guarenteed to compile first, so if any types,
-- constants, functions, etc., etc., are wanted, students should declare them
-- here.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

package RISCV_types is

  -- Example Constants. Declare more as needed
  constant DATA_WIDTH : integer := 32;
  constant ADDR_WIDTH : integer := 10;

  -- Example record type. Declare whatever types you need here
  type control_t is record
    reg_wr : std_logic;
    reg_to_mem : std_logic;
  end record control_t;

  constant OP_RTYPE  : std_logic_vector(6 downto 0) := "0110011";
  constant OP_ITYPE  : std_logic_vector(6 downto 0) := "0010011";
  constant OP_LOAD   : std_logic_vector(6 downto 0) := "0000011";
  constant OP_STORE  : std_logic_vector(6 downto 0) := "0100011";
  constant OP_BRANCH : std_logic_vector(6 downto 0) := "1100011";
  constant OP_JAL    : std_logic_vector(6 downto 0) := "1101111";
  constant OP_JALR   : std_logic_vector(6 downto 0) := "1100111";
  constant OP_LUI    : std_logic_vector(6 downto 0) := "0110111";
  constant OP_AUIPC  : std_logic_vector(6 downto 0) := "0010111";

  

  subtype ALU_CTL is std_logic_vector(3 downto 0);

  constant ALU_ADD  : ALU_CTL := "0000";
  constant ALU_SUB  : ALU_CTL := "0001";
  constant ALU_AND  : ALU_CTL := "0010";
  constant ALU_OR   : ALU_CTL := "0011";
  constant ALU_XOR  : ALU_CTL := "0100";
  constant ALU_SLL  : ALU_CTL := "0101";
  constant ALU_SRL  : ALU_CTL := "0110";
  constant ALU_SRA  : ALU_CTL := "0111";
  constant ALU_SLT  : ALU_CTL := "1000";
  constant ALU_SLTU : ALU_CTL := "1001";
  subtype alu_op_t is ALU_CTL;
  type wb_sel_t is (WB_ALU, WB_MEM, WB_PC4);

  type mem_size_t is (MS_B, MS_H, MS_W);

  function wb_sel_to_slv2(x : wb_sel_t) return std_logic_vector;

end package RISCV_types;

package body RISCV_types is
  -- Probably won't need anything here... function bodies, etc.
  function wb_sel_to_slv2(x : wb_sel_t) return std_logic_vector is
    variable y : std_logic_vector(1 downto 0);
  begin
    case x is
      when WB_ALU => y := "00";
      when WB_MEM => y := "01";
      when others => y := "10"; -- WB_PC4
    end case;
    return y;
  end function;
end package body RISCV_types;
