-- Isaiah Pridie
-- CprE 3810 proj01 fuckass xor_n gate file.
    -- Apparently I can't just generate 32 instancs of xor gates and hook a vector up to it. 
-- 2.17.2026,   9:30 MM

-- N-Bit xor
entity xor_N is
    generic(N : natural := 32); -- Natural ~= Unsigned* Integer*
    port(i_A : in std_logic_vector(N-1 downto 0);
         i_B : in std_logic_vector(N-1 downto 0);
         o_F : out std_logic_vector(N-1 downto 0));
end entity;

architecture structural of xor_N is

    component xorg2 is
        port(i_A          : in std_logic;
             i_B          : in std_logic;
             o_F          : out std_logic);
    end component;

begin
    G_nBit_XOR : for i in 0 to N-1 generate
        GenerateXOR : xorg2 port map(
            i_A => i_A(i),
            i_B => i_B(i),
            o_F => o_F(i) );
    end generate;

end architecture;