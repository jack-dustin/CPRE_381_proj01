library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32_pkg.all;

entity tb_ctrl_decoder is
end entity;

architecture sim of tb_ctrl_decoder is
  signal instr      : u32 := (others => '0');
  signal reg_we     : std_logic;
  signal alu_src    : std_logic;
  signal mem_we     : std_logic;
  signal mem_re     : std_logic;
  signal wb_sel     : wb_sel_t;
  signal is_branch  : std_logic;
  signal is_jal     : std_logic;
  signal is_jalr    : std_logic;
  signal alu_op     : alu_op_t;
  signal mem_sign   : std_logic;
  

  function mk_rtype(
    f7 : std_logic_vector(6 downto 0);
    f3 : std_logic_vector(2 downto 0)
  ) return u32 is
    variable i : u32 := (others => '0');
  begin
    i(31 downto 25) := f7;
    i(24 downto 20) := "00010";
    i(19 downto 15) := "00001";
    i(14 downto 12) := f3;
    i(11 downto 7)  := "00011";
    i(6 downto 0)   := OP_RTYPE;
    return i;
  end function;

  function mk_itype(
    f7 : std_logic_vector(6 downto 0);
    f3 : std_logic_vector(2 downto 0)
  ) return u32 is
    variable i : u32 := (others => '0');
  begin
    i(31 downto 25) := f7; -- used by srli/srai
    i(24 downto 20) := "00010";
    i(19 downto 15) := "00001";
    i(14 downto 12) := f3;
    i(11 downto 7)  := "00011";
    i(6 downto 0)   := OP_ITYPE;
    return i;
  end function;

  function mk_load(
    f3 : std_logic_vector(2 downto 0)
  ) return u32 is
    variable i : u32 := (others => '0');
  begin
    i(31 downto 20) := x"010";
    i(19 downto 15) := "00001";
    i(14 downto 12) := f3;
    i(11 downto 7)  := "00011";
    i(6 downto 0)   := OP_LOAD;
    return i;
  end function;

  function mk_store(
    f3 : std_logic_vector(2 downto 0)
  ) return u32 is
    variable i : u32 := (others => '0');
  begin
    i(31 downto 25) := "0000000";
    i(24 downto 20) := "00010";
    i(19 downto 15) := "00001";
    i(14 downto 12) := f3;
    i(11 downto 7)  := "00100";
    i(6 downto 0)   := OP_STORE;
    return i;
  end function;

  function mk_branch(
    f3 : std_logic_vector(2 downto 0)
  ) return u32 is
    variable i : u32 := (others => '0');
  begin
    i(31 downto 25) := "0000000";
    i(24 downto 20) := "00010";
    i(19 downto 15) := "00001";
    i(14 downto 12) := f3;
    i(11 downto 7)  := "00100";
    i(6 downto 0)   := OP_BRANCH;
    return i;
  end function;

  function mk_jal return u32 is
    variable i : u32 := (others => '0');
  begin
    i(11 downto 7) := "00011";
    i(6 downto 0)  := OP_JAL;
    return i;
  end function;

  function mk_jalr return u32 is
    variable i : u32 := (others => '0');
  begin
    i(31 downto 20) := x"004";
    i(19 downto 15) := "00001";
    i(14 downto 12) := "000";
    i(11 downto 7)  := "00011";
    i(6 downto 0)   := OP_JALR;
    return i;
  end function;

  function mk_lui return u32 is
    variable i : u32 := (others => '0');
  begin
    i(31 downto 12) := x"12345";
    i(11 downto 7)  := "00011";
    i(6 downto 0)   := OP_LUI;
    return i;
  end function;

  function mk_auipc return u32 is
    variable i : u32 := (others => '0');
  begin
    i(31 downto 12) := x"12345";
    i(11 downto 7)  := "00011";
    i(6 downto 0)   := OP_AUIPC;
    return i;
  end function;

  procedure expect(
    constant desc          : in string;
    constant exp_reg_we    : in std_logic;
    constant exp_alu_src   : in std_logic;
    constant exp_mem_we    : in std_logic;
    constant exp_mem_re    : in std_logic;
    constant exp_wb_sel    : in wb_sel_t;
    constant exp_is_branch : in std_logic;
    constant exp_is_jal    : in std_logic;
    constant exp_is_jalr   : in std_logic;
    constant exp_alu_op    : in alu_op_t;
    constant exp_mem_sign  : in std_logic
  ) is
  begin
    assert reg_we = exp_reg_we
      report desc & " : reg_we mismatch" severity error;
    assert alu_src = exp_alu_src
      report desc & " : alu_src mismatch" severity error;
    assert mem_we = exp_mem_we
      report desc & " : mem_we mismatch" severity error;
    assert mem_re = exp_mem_re
      report desc & " : mem_re mismatch" severity error;
    assert wb_sel = exp_wb_sel
      report desc & " : wb_sel mismatch" severity error;
    assert is_branch = exp_is_branch
      report desc & " : is_branch mismatch" severity error;
    assert is_jal = exp_is_jal
      report desc & " : is_jal mismatch" severity error;
    assert is_jalr = exp_is_jalr
      report desc & " : is_jalr mismatch" severity error;
    assert alu_op = exp_alu_op
      report desc & " : alu_op mismatch" severity error;
    assert mem_sign = exp_mem_sign
      report desc & " : mem_sign mismatch" severity error;
  end procedure;

begin
  dut : entity work.ctrl_decoder
    port map(
      instr      => instr,
      reg_we     => reg_we,
      alu_src    => alu_src,
      mem_we     => mem_we,
      mem_re     => mem_re,
      wb_sel     => wb_sel,
      is_branch  => is_branch,
      is_jal     => is_jal,
      is_jalr    => is_jalr,
      alu_op     => alu_op,
      mem_sign   => mem_sign
      
    );

  stim : process
  begin
    wait for 1 ns;

    -----------------------------------------------------------------------
    -- R-type base instructions
    -----------------------------------------------------------------------
    instr <= mk_rtype("0000000", "000"); wait for 1 ns; -- ADD
    expect("R: ADD",  '1','0','0','0',WB_ALU,'0','0','0',ALU_ADD,'1');

    instr <= mk_rtype("0100000", "000"); wait for 1 ns; -- SUB
    expect("R: SUB",  '1','0','0','0',WB_ALU,'0','0','0',ALU_SUB,'1');

    instr <= mk_rtype("0000000", "001"); wait for 1 ns; -- SLL
    expect("R: SLL",  '1','0','0','0',WB_ALU,'0','0','0',ALU_SLL,'1');

    instr <= mk_rtype("0000000", "010"); wait for 1 ns; -- SLT
    expect("R: SLT",  '1','0','0','0',WB_ALU,'0','0','0',ALU_SLT,'1');

    instr <= mk_rtype("0000000", "011"); wait for 1 ns; -- SLTU
    expect("R: SLTU", '1','0','0','0',WB_ALU,'0','0','0',ALU_SLTU,'1');

    instr <= mk_rtype("0000000", "100"); wait for 1 ns; -- XOR
    expect("R: XOR",  '1','0','0','0',WB_ALU,'0','0','0',ALU_XOR,'1');

    instr <= mk_rtype("0000000", "101"); wait for 1 ns; -- SRL
    expect("R: SRL",  '1','0','0','0',WB_ALU,'0','0','0',ALU_SRL,'1');

    instr <= mk_rtype("0100000", "101"); wait for 1 ns; -- SRA
    expect("R: SRA",  '1','0','0','0',WB_ALU,'0','0','0',ALU_SRA,'1');

    instr <= mk_rtype("0000000", "110"); wait for 1 ns; -- OR
    expect("R: OR",   '1','0','0','0',WB_ALU,'0','0','0',ALU_OR,'1');

    instr <= mk_rtype("0000000", "111"); wait for 1 ns; -- AND
    expect("R: AND",  '1','0','0','0',WB_ALU,'0','0','0',ALU_AND,'1');

    -----------------------------------------------------------------------
    -- RV32M instructions
    -----------------------------------------------------------------------
    instr <= mk_rtype("0000001", "000"); wait for 1 ns; -- MUL
    expect("M: MUL",    '1','0','0','0',WB_ALU,'0','0','0',ALU_MUL,'1');

    instr <= mk_rtype("0000001", "001"); wait for 1 ns; -- MULH
    expect("M: MULH",   '1','0','0','0',WB_ALU,'0','0','0',ALU_MULH,'1');

    instr <= mk_rtype("0000001", "010"); wait for 1 ns; -- MULHSU
    expect("M: MULHSU", '1','0','0','0',WB_ALU,'0','0','0',ALU_MULHSU,'1');

    instr <= mk_rtype("0000001", "011"); wait for 1 ns; -- MULHU
    expect("M: MULHU",  '1','0','0','0',WB_ALU,'0','0','0',ALU_MULHU,'1');

    instr <= mk_rtype("0000001", "100"); wait for 1 ns; -- DIV
    expect("M: DIV",    '1','0','0','0',WB_ALU,'0','0','0',ALU_DIV,'1');

    instr <= mk_rtype("0000001", "101"); wait for 1 ns; -- DIVU
    expect("M: DIVU",   '1','0','0','0',WB_ALU,'0','0','0',ALU_DIVU,'1');

    instr <= mk_rtype("0000001", "110"); wait for 1 ns; -- REM
    expect("M: REM",    '1','0','0','0',WB_ALU,'0','0','0',ALU_REM,'1');

    instr <= mk_rtype("0000001", "111"); wait for 1 ns; -- REMU
    expect("M: REMU",   '1','0','0','0',WB_ALU,'0','0','0',ALU_REMU,'1');

    -----------------------------------------------------------------------
    -- I-type arithmetic instructions
    -----------------------------------------------------------------------
    instr <= mk_itype("0000000", "000"); wait for 1 ns; -- ADDI
    expect("I: ADDI",  '1','1','0','0',WB_ALU,'0','0','0',ALU_ADD,'1');

    instr <= mk_itype("0000000", "001"); wait for 1 ns; -- SLLI
    expect("I: SLLI",  '1','1','0','0',WB_ALU,'0','0','0',ALU_SLL,'1');

    instr <= mk_itype("0000000", "010"); wait for 1 ns; -- SLTI
    expect("I: SLTI",  '1','1','0','0',WB_ALU,'0','0','0',ALU_SLT,'1');

    instr <= mk_itype("0000000", "011"); wait for 1 ns; -- SLTIU
    expect("I: SLTIU", '1','1','0','0',WB_ALU,'0','0','0',ALU_SLTU,'1');

    instr <= mk_itype("0000000", "100"); wait for 1 ns; -- XORI
    expect("I: XORI",  '1','1','0','0',WB_ALU,'0','0','0',ALU_XOR,'1');

    instr <= mk_itype("0000000", "101"); wait for 1 ns; -- SRLI
    expect("I: SRLI",  '1','1','0','0',WB_ALU,'0','0','0',ALU_SRL,'1');

    instr <= mk_itype("0100000", "101"); wait for 1 ns; -- SRAI
    expect("I: SRAI",  '1','1','0','0',WB_ALU,'0','0','0',ALU_SRA,'1');

    instr <= mk_itype("0000000", "110"); wait for 1 ns; -- ORI
    expect("I: ORI",   '1','1','0','0',WB_ALU,'0','0','0',ALU_OR,'1');

    instr <= mk_itype("0000000", "111"); wait for 1 ns; -- ANDI
    expect("I: ANDI",  '1','1','0','0',WB_ALU,'0','0','0',ALU_AND,'1');

    -----------------------------------------------------------------------
    -- Loads
    -----------------------------------------------------------------------
    instr <= mk_load("000"); wait for 1 ns; -- LB
    expect("LD: LB",  '1','1','0','1',WB_MEM,'0','0','0',ALU_ADD,'1');

    instr <= mk_load("001"); wait for 1 ns; -- LH
    expect("LD: LH",  '1','1','0','1',WB_MEM,'0','0','0',ALU_ADD,'1');

    instr <= mk_load("010"); wait for 1 ns; -- LW
    expect("LD: LW",  '1','1','0','1',WB_MEM,'0','0','0',ALU_ADD,'1');

    instr <= mk_load("100"); wait for 1 ns; -- LBU
    expect("LD: LBU", '1','1','0','1',WB_MEM,'0','0','0',ALU_ADD,'0');

    instr <= mk_load("101"); wait for 1 ns; -- LHU
    expect("LD: LHU", '1','1','0','1',WB_MEM,'0','0','0',ALU_ADD,'0');

    -----------------------------------------------------------------------
    -- Stores
    -----------------------------------------------------------------------
    instr <= mk_store("000"); wait for 1 ns; -- SB
    expect("ST: SB", '0','1','1','0',WB_ALU,'0','0','0',ALU_ADD,'1');

    instr <= mk_store("001"); wait for 1 ns; -- SH
    expect("ST: SH", '0','1','1','0',WB_ALU,'0','0','0',ALU_ADD,'1');

    instr <= mk_store("010"); wait for 1 ns; -- SW
    expect("ST: SW", '0','1','1','0',WB_ALU,'0','0','0',ALU_ADD,'1');

    -----------------------------------------------------------------------
    -- Branches
    -----------------------------------------------------------------------
    instr <= mk_branch("000"); wait for 1 ns; -- BEQ
    expect("B: BEQ",  '0','0','0','0',WB_ALU,'1','0','0',ALU_ADD,'1');

    instr <= mk_branch("001"); wait for 1 ns; -- BNE
    expect("B: BNE",  '0','0','0','0',WB_ALU,'1','0','0',ALU_ADD,'1');

    instr <= mk_branch("100"); wait for 1 ns; -- BLT
    expect("B: BLT",  '0','0','0','0',WB_ALU,'1','0','0',ALU_ADD,'1');

    instr <= mk_branch("101"); wait for 1 ns; -- BGE
    expect("B: BGE",  '0','0','0','0',WB_ALU,'1','0','0',ALU_ADD,'1');

    instr <= mk_branch("110"); wait for 1 ns; -- BLTU
    expect("B: BLTU", '0','0','0','0',WB_ALU,'1','0','0',ALU_ADD,'1');

    instr <= mk_branch("111"); wait for 1 ns; -- BGEU
    expect("B: BGEU", '0','0','0','0',WB_ALU,'1','0','0',ALU_ADD,'1');

    -----------------------------------------------------------------------
    -- Jumps + U-type
    -----------------------------------------------------------------------
    instr <= mk_jal; wait for 1 ns;
    expect("J: JAL",   '1','0','0','0',WB_PC4,'0','1','0',ALU_ADD,'1');

    instr <= mk_jalr; wait for 1 ns;
    expect("J: JALR",  '1','1','0','0',WB_PC4,'0','0','1',ALU_ADD,'1');

    instr <= mk_lui; wait for 1 ns;
    expect("U: LUI",   '1','1','0','0',WB_ALU,'0','0','0',ALU_COPY_B,'1');

    instr <= mk_auipc; wait for 1 ns;
    expect("U: AUIPC", '1','1','0','0',WB_ALU,'0','0','0',ALU_ADD,'1');

    -----------------------------------------------------------------------
    -- Invalid / other opcode default
    -----------------------------------------------------------------------
    instr <= (others => '0'); wait for 1 ns;
    expect("OTHER", '0','0','0','0',WB_ALU,'0','0','0',ALU_ADD,'1');

    report "tb_ctrl_decoder: ALL TESTS PASSED" severity note;
    wait;
  end process;

end architecture;
