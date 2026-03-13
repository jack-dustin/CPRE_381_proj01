-- -- Isaiah Pridie
-- -- CprE 381 project01 - Load file for lw, lhw, lb
-- -- 3.13.2026,    10:24

-- library IEEE;
-- use IEEE.std_logic_1164.all;
-- use IEEE.numeric_std.all;

-- entity proj01_LOAD is
--     port(i_memVal       : in  std_logic_vector(31 downto 0);
--          c_addr_2bit    : in  std_logic_vector(1  downto 0);    -- Lower 2 bits of DMEM addr
--          c_funct3       : in  std_logic_vector(2  downto 0);    

--          o_LoadOut      : out std_logic_vector(31 downto 0));
-- end entity;

-- architecture structural of proj01_LOAD is
--     -- Given: 0x12345678

--     -- Sign Extend by storing and using first bit of every byte
--     signal s_ex             : std_logic_vector(3  downto 0);        

--     -- Byte Signals
--     signal s_byte00         : std_logic_vector(31 downto 0);        -- 0x78 
--     signal s_byte01         : std_logic_vector(31 downto 0);        -- 0x56
--     signal s_byte10         : std_logic_vector(31 downto 0);        -- 0x34
--     signal s_byte11         : std_logic_vector(31 downto 0);        -- 0x12

--     -- Byte Mux Signals
--         -- s_byte00 \
--         -- s_byte01 --- mux_0 \   
--         --                     |____ mux_3 
--         -- s_byte10 --- mux_1 /
--         -- s_byte11 /
--     signal s_mux_b0_m2      : std_logic_vector(31 downto 0);        -- Carries signal from mux_b0 to mux_b2             -- c_addr_2bit(0)
--     signal s_mux_b1_m2      : std_logic_vector(31 downto 0);        -- Carries signal from mux_b1 to mux_b2             -- c_addr_2bit(1)
--     signal s_mux_b2_m4      : std_logic_vector(31 downto 0);        -- Carries signal from mux_b2 to mux_bhw4           -- c_funct3(0)
    
--     -- Half-Word Signals
--     signal s_hw0            : std_logic_vector(31 downto 0);        -- 0x5678
--     signal s_hw1            : std_logic_vector(31 downto 0);        -- 0x1234

--     -- Half-Word Mux Signals
--         -- s_hw0 \
--         -- s_hw1 ----- mux_hw3_bhw4
--     signal s_mux_hw3_m4     : std_logic_vector(31 downto 0);        -- Carries signal from word mux to byte o word mux

--     -- Half-Word or Byte mux signal to previous or word mux signal
--         --  mux_b2_m4 \ 
--         -- mux_hw3_m4 ----- mux_m4_m5
--     signal s_mux_m4_m5      : std_logic_vector(31 downto 0);


--     component busMux_2t1 is
--         port(i_dZero    : in  std_logic_vector(31 downto 0);
--              i_dOne     : in  std_logic_vector(31 downto 0);
--              ALUSrc     : in  std_logic; -- select line
--              o_dOUT     : out std_logic_vector(31 downto 0));
--     end component;

-- begin

--     -- Get appropriate bits to sign extend
--     s_ex(3)     <= i_memVal(31) AND (NOT c_funct3(2));
--     s_ex(2)     <= i_memVal(23) AND (NOT c_funct3(2));
--     s_ex(1)     <= i_memVal(15) AND (NOT c_funct3(2));
--     s_ex(0)     <= i_memVal(7)  AND (NOT c_funct3(2));


--     -- Assigning correct section of word to byte signals + sign extending
--     s_byte_00   <= (31 downto 8 => s_ex(3)) & i_Da(31 downto 24);   -- 0x------12
--     s_byte_01   <= (31 downto 8 => s_ex(3)) & i_Da(23 downto 16);   -- 0x------34
--     s_byte_10   <= (31 downto 8 => s_ex(3)) & i_Da(15 downto 8);    -- 0x------56
--     s_byte_11   <= (31 downto 8 => s_ex(3)) & i_Da(7 downto 0);     -- 0x------78


--     INST_BUSMUX_0: busMux_2t1 port map(     -- Choose between first two byte inputs
--         i_dZero     => s_byte00,    -- 0x78
--         i_dOne      => s_byte01,    -- 0x56
--         ALUSrc      => c_addr_2bit(0),      -- i_addr(0)
--         o_dOUT      => s_mux_b0_m2);        -- Result to mux 2

--     INST_BUSMUX_1: busMux_2t1 port map(     -- Choose between second two byte inputs
--         i_dZero     => s_byte10,    -- 0x34
--         i_dOne      => s_byte11,    -- 0x12
--         ALUSrc      => c_addr_2bit(0),      -- i_addr(0)
--         o_dOUT      => s_mux_b1_m2);        -- Result to mux 2

--     INST_BUSMUX_2: busMux_2t1 port map(     -- Mux 0 + 1   =   2
--         i_dZero     => s_mux_b0_m2, -- Mux 0
--         i_dOne      => s_mux_b1_m2, -- Mux 1
--         ALUSrc      => c_addr_2bit(1),      -- i_addr(0)
--         o_dOUT      => s_mux_b2_m4);        -- Result to mux 4

--     INST_BUSMUX_3: busMux_2t1 port map(     -- Choose between two half-word inputs
--         i_dZero     => s_hw0,       -- 0x5678
--         i_dOne      => s_hw1,       -- 0x1234
--         ALUSrc      => c_addr_2bit(1),      -- i_addr(0)
--         o_dOUT      => s_mux_hw3_m4);       -- Result to mux 4   

--     INST_BUSMUX_4: busMux_2t1 port map(     -- Choose between byte and half-word
--         i_dZero     => s_mux_b2_m4, -- Byte Mux Result
--         i_dOne      => s_mux_hw3_m4,-- Half-Word Mux Result
--         ALUSrc      => c_funct3(0),
--         o_dOUT      => s_mux_m4_m5);

--     INST_BUSMUX_5: busMux_2t1 port map(     -- Choose between prior result and word
--         i_dZero     => s_mux_m4_m5,
--         i_dOne      => i_memVal,
--         ALUSrc      => c_funct3(1),
--         o_dOUT      => o_LoadOut);









-- end architecture;

