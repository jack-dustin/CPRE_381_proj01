-- Isaiah Pridie
-- CprE 3810 Lab1 Part 3.4
-- Start Date: 2.9.2026, 3:17 PM

library ieee;
use IEEE.std_logic_1164.all;

entity tb_reg_n is
    generic(gCLK_HPER   : time := 50 ns);
end entity;

architecture reg_n of tb_reg_n is
    -- Calculate the clock period as twice the half-period
    constant cCLK_PER  : time := gCLK_HPER * 2;

    constant N : integer := 32; -- this can be changed for other tests

    -- declare signals to show up on questa sim
    -- initiallize bus/data values as 0
    signal is_CLK   : std_logic;    -- Show clock
    signal is_RST   : std_logic;    -- Show reset
    signal is_WE    : std_logic;    -- Show Write EN
    signal is_D     : std_logic_vector(N-1 downto 0) := (others => '0');
    signal os_Q     : std_logic_vector(N-1 downto 0) := (others => '0');

    component reg_n is 
        generic (N : natural := 4); -- 4 by default; changes by on declr. above
        -- 'natural' -> cannot be less than 0  |  Cannot be a value; it is a size
        -- easier to avoid stupid bugs using natural (allegedly)
        port (i_CLK   : in std_logic;                          -- Clock input
              i_RST   : in std_logic;                          -- Reset input
              i_WE    : in std_logic;                          -- Write enable input
              i_D     : in std_logic_vector(N-1 downto 0);     -- (Bus) Data value input
              o_Q     : out std_logic_vector(N-1 downto 0));   -- (Bus) Data value output
    end component;

    begin
        DUT: reg_n
            -- left N is DUT (Comp.). Right N is Arch. (signals)
            generic map (N => N)
            port map (
                i_CLK   => is_CLK,
                i_RST   => is_RST,
                i_WE    => is_WE,
                i_D     => is_D,
                o_Q     => os_Q  );

        -- This process sets the clock value (low for gCLK_HPER, then high
        -- for gCLK_HPER). Absent a "wait" command, processes restart 
        -- at the beginning once they have reached the final statement.
        P_CLK: process
        begin
            is_CLK <= '0';
            wait for gCLK_HPER;
            is_CLK <= '1';
            wait for gCLK_HPER;
        end process;

        -- Testbench Process
        reg_TB: process
        variable var0 : std_logic_vector(N-1 downto 0);  -- helpful for loading vairbale inputs
        variable var1 : std_logic_vector(N-1 downto 0);  -- helpful for loading vairbale inputs
        variable var2 : std_logic_vector(N-1 downto 0);  -- helpful for loading vairbale inputs
        variable var3 : std_logic_vector(N-1 downto 0);  -- helpful for loading vairbale inputs
        begin
            -- atrocious looking loop.
                -- would be WAY better off as 2 separate loops
                -- I don't care anymore lol
                -- It gets the job done
                -- Leave me alone, bitch!
            -- var0 = ...10101010
            -- var1 = ...01010101
            -- var2 = ...11001100
            -- var3 = ...00110011
            for k in 0 to N-1 loop
                if (k mod 2 = 0) then
                    var0(k) := '0'; 
                    var1(k) := '1';

                    if (k < N-1) then
                    if (N mod 2 = 0) then
                        if ( ((k / 2) mod 2 = 0) ) then -- if rem. is even
                            var2(k)    := '0';
                            var2(k+1)  := '0';
                            var3(k)    := '1';
                            var3(k+1)  := '1';
                        else
                            var2(k)    := '1';
                            var2(k+1)  := '1';
                            var3(k)    := '0';
                            var3(k+1)  := '0';
                        end if;
                    end if;
                    end if;
                else 
                    var0(k) := '1';
                    var1(k) := '0';
                end if;
            end loop;

            -- Start Test Cases:
                    
            ------ Test Case 1 ------
            -- Check contents of register BEFORE reset
            is_RST  <= '0';  -- immediately set to 0
            wait for cCLK_PER;
            null;   -- Null Statement (no-op)
            wait for cCLK_PER;
            -- Expecting unknown values (Red Lines)

            ------ Test Case 2 ------
            -- Check contents of register AFTER reset
            is_RST  <= '1';  
            wait for cCLK_PER;
            -- Expecting all 0s

            ------ Test Case 3 ------
            -- Try writing to register while write bit is 0
            is_RST  <= '0'; -- reset b = 0
            is_WE   <= '0'; -- write EN b = 0
            wait for cCLK_PER;  -- wait for action to take effect
            is_D    <= (others => '1'); -- set ALL bits to 1
            wait for cCLK_PER;
            -- Expecting register contents to NOT change

            ------ Test Case 4 ------
            -- Try writing to register when write bit is 1
            is_RST  <= '0'; -- reset b = 0
            is_WE   <= '1';
            wait for cCLK_PER;
            is_D    <= (others => '1'); -- set ALL bits to 1
            wait for cCLK_PER;
            -- Expecting register contents to become all 1s

            ------ Case 5 ------
            -- Try writing to register when write bit and reset are 1
            is_RST  <= '1';
            is_WE   <= '1';
            wait for cCLK_PER;
            is_D    <= (others => '1'); -- set ALL bits to 1
            wait for cCLK_PER;
            -- Expectig Reset to take precedence
                -- Expecting all 0s

            ------ Test Case 6 ------
            -- Alternate between 101010... and 010101...
            is_RST  <= '0';
            is_WE   <= '1';
            wait for cCLK_PER;

            for k in 0 to 2 loop
                is_D    <= var0;
                wait for cCLK_PER;
                is_D    <= var1;
                wait for cCLK_PER;
            end loop;
            -- Expecting register output to switch between 1010 and 0101 pattterns

            ------ Test Case 7 ------
            -- Alternate between 11001100... and 00110011...
            is_RST  <= '0';
            is_WE   <= '1';
            wait for cCLK_PER;

            for k in 0 to 2 loop
                is_D    <= var2;
                wait for cCLK_PER;
                is_D    <= var3;
                wait for cCLK_PER;
            end loop;
            -- Expecting reg output to switch between 11001100 and 00110011

            ------ Test Case 8 ------
            -- ...
            
            wait;
        end process;
end architecture;

