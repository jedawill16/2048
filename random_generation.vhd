library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity random_generation is
  port(
    clk           : in  std_logic;
    reset         : in  std_logic;
    spawn_en      : in  std_logic;
    occupied_cells: in  std_logic_vector(15 downto 0);

    spawn_valid   : out std_logic;
    spawn_row     : out std_logic_vector(1 downto 0);
    spawn_col     : out std_logic_vector(1 downto 0);
    spawn_value   : out std_logic_vector(3 downto 0)
  );
end random_generation;

architecture behavior of random_generation is
  signal lfsr : unsigned(7 downto 0) := x"5A";
begin
  process(clk, reset)
    variable start_idx : integer;
    variable idx       : integer;
    variable found     : boolean;
  begin
    if reset = '1' then
      lfsr        <= x"5A";
      spawn_valid <= '0';
      spawn_row   <= (others => '0');
      spawn_col   <= (others => '0');
      spawn_value <= "0001";

    elsif rising_edge(clk) then
      lfsr <= lfsr(6 downto 0) & (lfsr(7) xor lfsr(5) xor lfsr(4) xor lfsr(3));

      spawn_valid <= '0';
      spawn_value <= "0001";

      if spawn_en = '1' then
        start_idx := to_integer(lfsr(3 downto 0));
        found := false;

        for k in 0 to 15 loop
          idx := (start_idx + k) mod 16;

          if occupied_cells(idx) = '0' and (not found) then
            spawn_valid <= '1';
            spawn_row   <= std_logic_vector(to_unsigned(idx / 4, 2));
            spawn_col   <= std_logic_vector(to_unsigned(idx mod 4, 2));
            found := true;
          end if;
        end loop;
      end if;
    end if;
  end process;
end behavior;