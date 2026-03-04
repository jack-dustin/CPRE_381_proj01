-- Isaiah Pridie
-- CprE 3810 Lab2 Part 5.c
-- Start Ddate: 2.20.2026,  10:29 AM

-- mem load -infile dmem.hex -format hex /tb_dmem/DUT/ram

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_dmem is
    generic(gCLK_HPER   : time := 50 ns);
end entity;


architecture mem of tb_dmem is 
    -- Calculate the clock period as twice the half-period
    constant cCLK_PER   : time := gCLK_HPER * 2;
    -- Refefine constants so tb knows what memory looks like. 
    constant ADDR_WIDTH : natural := 10;
    constant DATA_WIDTH : natural := 32;


    -- Declare/initialize signals (what we can see in questasim)
        signal is_clk   : std_logic;
    -- Add height (how many) addresses there are (2^10 addresses)
        signal is_addr  : std_logic_vector((ADDR_WIDTH-1) downto 0) := (others => '0');  
    -- Add and initialize address
        signal is_data  : std_logic_vector((DATA_WIDTH - 1) downto 0) := (others => '0');
    -- Write EN for writing values in data to RAM (memory)
        signal is_we   : std_logic := '1';
    -- Signal for showing output of our memory (i.e. reads from memory). Initialize to 0 -> no initial garbage
        signal os_q     : std_logic_vector((DATA_WIDTH - 1) downto 0) := (others => '0');


    -- Component
    component mem is            -- redefine mem entity ports
    port(clk    : in std_logic;
         addr   : in std_logic_vector((ADDR_WIDTH-1) downto 0);
		 data   : in std_logic_vector((DATA_WIDTH-1) downto 0);
		 we		: in std_logic := '1';
		 q		: out std_logic_vector((DATA_WIDTH -1) downto 0) );
    end component;


    begin
    DUT: mem    ------ 5.c.a ------     (Component Instantiation)
        -- Components => signals
        port map(clk    => is_clk,
                 addr   => is_addr,
                 data   => is_data,
                 we     => is_we,
                 q      => os_q);
    
    -- Clock Go BRRRR
    P_CLK: process
    begin
        is_CLK <= '0';
        wait for gCLK_HPER;
        is_CLK <= '1';
        wait for gCLK_HPER;
    end process;
    -- End Clock Go BRRRRR    :(

    TEST_CASES: process 
    begin

        ------ 5.c.b ------     -- Read values from hex file
        is_we       <= '0';     -- We are only reading RIGHT NOW. Not writing
        is_addr     <= "0000000000";     -- start at address 0
        for k in 0 to 9 loop
            wait for gCLK_HPER;
            if k /= 9 then              -- don't output anything extra
                is_addr <= std_logic_vector(unsigned(is_addr) + 1);     -- increment address by 1 to get to the next address (bytes, not words)
            end if;
        end loop;

        wait until rising_edge(is_clk);      

        ------ 5.c.c ------     -- Write same values just read prior starting at address x100
        is_we       <= '1';             -- Write same values we previous read

        is_addr     <= "0001100100";          -- start at address 100
        is_data     <= x"FFFFFFFF";     -- -1
        wait until rising_edge(is_clk);     -- Writes on positive edge of the clock

        is_addr     <= "0001100101";          -- Next address at 101
        is_data     <= x"00000002";     --  2
        wait until rising_edge(is_clk);

        is_addr     <= "0001100110";          -- Next address at 102
        is_data     <= x"FFFFFFFD";     -- -3
        wait until rising_edge(is_clk);

        is_addr     <= "0001100111";          -- Next address at 103
        is_data     <= x"00000004";     --  4
        wait until rising_edge(is_clk);

        is_addr     <= "0001101000";          -- Next address at 104
        is_data     <= x"00000005";     --  5
        wait until rising_edge(is_clk);

        is_addr     <= "0001101001";          -- Next address at 105
        is_data     <= x"00000006";     --  6
        wait until rising_edge(is_clk);

        is_addr     <= "0001101010";          -- Next address at 106
        is_data     <= x"FFFFFFF9";     -- -7
        wait until rising_edge(is_clk);

        is_addr     <= "0001101011";          -- Next address at 107
        is_data     <= x"FFFFFFF8";     -- -8
        wait until rising_edge(is_clk);

        is_addr     <= "0001101100";          -- Next address at 108
        is_data     <= x"00000009";     --  9
        wait until rising_edge(is_clk);

        is_addr     <= "0001101101";          -- Next address at 109
        is_data     <= x"FFFFFFF6";     -- -10
        wait until rising_edge(is_clk);       -- Writing only happens on the positive edge

        is_we       <= '0';             -- turn write enable bit off

        ------ 5.c.d ------     -- Read same values that were just written
        is_addr     <= "0001100100";          -- Start at address x100
        -- is_we is already set to 0
        for k in 0 to 9 loop
            wait for gCLK_HPER;             -- Positive edge does not matter when reading
            if k /= 9 then
                is_addr <= std_logic_vector(unsigned(is_addr) + 1);     -- increment address by 1 to get to the next address (bytes, not words)
            end if;
        end loop;

    wait;
    end process;
end architecture;
