library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity random_generation is
  port(
    clk        : in  std_logic;
    reset      : in  std_logic;
    spawn_en   : in  std_logic;
    board_in   : in  std_logic_vector(63 downto 0);
    board_out  : out std_logic_vector(63 downto 0)
  );
end random_generation;

architecture behavior of random_generation is
  signal rand_ctr : unsigned(7 downto 0) := x"5A";
begin

  process(clk, reset)
    variable temp_board : std_logic_vector(63 downto 0);
    variable start_idx  : integer;
    variable idx        : integer;
    variable found      : boolean;
    variable cell_bits  : integer;
  begin
    if reset = '1' then
      rand_ctr <= x"5A";
      board_out <= (others => '0');

    elsif rising_edge(clk) then
      rand_ctr <= rand_ctr + 1;
      temp_board := board_in;

      if spawn_en = '1' then
        start_idx := to_integer(rand_ctr(3 downto 0));
        found := false;

        for offset in 0 to 15 loop
          idx := (start_idx + offset) mod 16;
          cell_bits := idx * 4;

          if temp_board(cell_bits+3 downto cell_bits) = "0000" and not found then
            temp_board(cell_bits+3 downto cell_bits) := "0001"; -- spawn a 2
            found := true;
          end if;
        end loop;
      end if;

      board_out <= temp_board;
    end if;
  end process;

end behavior;