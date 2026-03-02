-- Isaiah Pridie
-- CprE 3810 Lab1 Part 3.4
-- Start Date: 2.4.2026, 7:30 PM

library ieee;
use IEEE.std_logic_1164.all;

entity tb_addSub is
end entity;

architecture AdderSubber of tb_addSub is
    constant N : integer := 32;     -- We can change this value later

    -- create signals to make waves visible
    signal  i_Da      :   std_logic_vector(N-1 downto 0) := (others => '0');
    signal  i_Db      :   std_logic_vector(N-1 downto 0) := (others => '0');
    signal  nAdd_Sub  :   std_logic := '0';  -- used for control. Initialized to 0
    signal  o_Sum     :   std_logic_vector(N-1 downto 0);
    signal  o_Car     :   std_logic;  -- used for last carry out bit

    component addSub is
        generic (N : natural := 32);    -- now 32 by default
        port (  i_Da      : in std_logic_vector(N-1 downto 0);
                i_Db      : in std_logic_vector(N-1 downto 0);
                nAdd_Sub  : in std_logic;   -- used as control/carry
                o_Sum     : out std_logic_vector(N-1 downto 0);
                o_Car     : out std_logic);
    end component;

    begin
        DUT: addSub
        -- Left N is Component's ports. Right side is Signals/This files ports
        generic map (N => N)
        port map (  i_Da      => i_Da,
                    i_Db      => i_Db,
                    nAdd_Sub  => nAdd_Sub,
                    o_Sum     => o_Sum,
                    o_Car     => o_Car  );
    process
    variable var : std_logic_vector(N-1 downto 0);
    begin
        -- load initial signals for test values . . .
        nAdd_Sub <= '0';
        i_Da  <=  (others => '0');  -- start A and B at 0
        i_Db  <=  (others => '0');

        -- Do same (4) tests first as the adder tests


        ----------   Case 1:   ----------
        -- Try 101010... + 0
        for k in 0 to N-1 loop
            if (k mod 2 = 0) then
                    var(k) := '0';
                else
                    var(k) := '1';
                end if;
            end loop;
                
            i_Da  <= var;    -- assign input
            wait for 10 ns;
            -- expecting  <-...101010  +  ...0000  =  ...101010


        ----------   Test Case 2:   ----------
        -- add  1010  +  01010  =  1111
        for k in 0 to N-1 loop
            if (var(k) = '1') then
                var(k) := '0';
            else    -- it is 0 -> set to 1
                var(k) := '1';
            end if;
        end loop;

        i_Db  <= var;  -- assign input
        wait for 10 ns;
        -- expecting  <-...101010  +  <-...010101  =  ...111111


        ----------   Test Case 3:   ----------
        -- add  0111...1111  +  000...00001  =  100...000
        -- Check carry across entire entity
        i_Da      <= (others => '1');  -- set all to 1
        i_Da(N-1) <= '0';         -- set MSB to 0

        -- 0000...0001
        i_Db      <= (others => '0');  -- set all to 0
        i_Db(0)   <= '1';           -- set LSB to 1

        wait for 10 ns;
        -- expecting  1000...0000            


        ----------   Test Case 4:   ----------
        -- Test carry out bit
        -- Add  100...  +  100.. 
        i_Da      <= (others => '0');  -- set all to 0
        i_Da(N-1) <= '1';     -- set MSB to 1

        i_Db      <= (others => '0');  -- set all to 0
        i_Db(N-1) <= '1';     -- set MSB to 1

        wait for 10 ns;
        -- Expecting Carry_out to be 1


        ----------   Test Case 5:   ----------
        -- Test adding 0 to 0
        i_Da      <= (others => '0');  -- set all to 0
        i_Db      <= (others => '0');  -- set all to 0

        wait for 10 ns;
        -- Expecting sum to be 0


        ----------   Test Case 6:   ----------
        -- Testing adding 0 to 0 when nAdd_Sub IS 1
        nAdd_Sub <= '1';

        wait for 10 ns;
        -- Expecting sum to be 0


        ----------   Test Case 7:   ----------
        -- Set A with x, set B with x. Subtract B from A
        for k in 0 to N-1 loop
            if (k mod 3 = 0) then
                var(k) := '0';
            else
                var(k) := '1';
            end if; 
        end loop;
                
        i_Da <= var;
        i_Db <= var;
            
        wait for 10 ns;
        -- expecting 0                


        ----------   Test Case 8:   ----------
        -- Subtract a number from 0
        i_Da <= (others => '0');
        i_Db <= var;    

        wait for 10 ns;
        -- expecting a negative value


        -- ----------   Test Case 9:   ----------
        -- -- Add 20 20 times - iterative/ edge-case test
        -- nAdd_Sub <= '0';
        -- i_Da <= (others => '0');
        -- i_Db <= x"00000014";-- i_Db = 20

        -- for k in 0 to 20 loop
        --     wait for 0.5 ns;
        -- end loop;
        -- wait for 10 ns;
        -- -- Expecting i_Da to have 20 more than before

        
        ----------   Test Case 9:   ----------
        -- Do 0 - 1  - Checking edge case
        nAdd_Sub <= '1';
        i_Da <= (others => '0');
        i_Db <= (others => '0');
        i_Db(0) <= '1'; -- least significant bit = 1
        wait for 10 ns;

        ----------   Test Case 10:   ----------
        -- 0x80000000 - 1 = 0x7FFFFFFF. Needs to borrow from MSB
        i_Da <= (others => '0');
        i_Da(N-1) <= '1';   -- MSB = 1
        i_Db <= (others => '0');
        i_Db(0) <= '1'; -- LSB = 1
        wait for 10 ns;
        -- Expect 0x7FFFFFFF

        wait;
    end process;
end architecture;


        

