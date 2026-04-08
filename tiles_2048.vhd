library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tiles_2048 is
  port(
    pixel_row    : in  std_logic_vector(10 downto 0);
    pixel_column : in  std_logic_vector(10 downto 0);

    tile_active  : in  std_logic_vector(15 downto 0);
    tile_value   : in  std_logic_vector(63 downto 0);
    tile_x_bus   : in  std_logic_vector(175 downto 0);
    tile_y_bus   : in  std_logic_vector(175 downto 0);

    tile_on      : out std_logic;
    Red          : out std_logic_vector(7 downto 0);
    Green        : out std_logic_vector(7 downto 0);
    Blue         : out std_logic_vector(7 downto 0)
  );
end tiles_2048;

architecture behavior of tiles_2048 is
  constant CELL_SIZE : integer := 120;
begin
  process(pixel_row, pixel_column, tile_active, tile_value, tile_x_bus, tile_y_bus)
    variable x, y      : integer;
    variable tx, ty    : integer;
    variable val       : integer;
    variable hit       : boolean;
  begin
    x := to_integer(unsigned(pixel_column));
    y := to_integer(unsigned(pixel_row));

    tile_on <= '0';
    Red     <= (others => '0');
    Green   <= (others => '0');
    Blue    <= (others => '0');

    hit := false;

    for i in 0 to 15 loop
      tx  := to_integer(unsigned(tile_x_bus(i*11+10 downto i*11)));
      ty  := to_integer(unsigned(tile_y_bus(i*11+10 downto i*11)));
      val := to_integer(unsigned(tile_value(i*4+3 downto i*4)));

      if tile_active(i) = '1' then
        if (x >= tx) and (x < tx + CELL_SIZE) and
           (y >= ty) and (y < ty + CELL_SIZE) and
           (not hit) then

          tile_on <= '1';
          hit := true;

          case val is
            when 1  => Red <= x"FF"; Green <= x"00"; Blue <= x"00"; -- 2 red
            when 2  => Red <= x"FF"; Green <= x"88"; Blue <= x"00"; -- 4 orange
            when 3  => Red <= x"FF"; Green <= x"FF"; Blue <= x"00"; -- 8 yellow
            when 4  => Red <= x"99"; Green <= x"FF"; Blue <= x"00"; -- 16 lime
            when 5  => Red <= x"00"; Green <= x"AA"; Blue <= x"00"; -- 32 green
            when 6  => Red <= x"66"; Green <= x"CC"; Blue <= x"FF"; -- 64 baby blue
            when 7  => Red <= x"00"; Green <= x"44"; Blue <= x"CC"; -- 128 blue
            when 8  => Red <= x"88"; Green <= x"00"; Blue <= x"CC"; -- 256 purple
            when 9  => Red <= x"FF"; Green <= x"00"; Blue <= x"AA"; -- 512 magenta
            when 10 => Red <= x"FF"; Green <= x"CC"; Blue <= x"DD"; -- 1024 light pink
            when others =>
              Red <= x"FF"; Green <= x"FF"; Blue <= x"FF"; -- 2048 white
          end case;
        end if;
      end if;
    end loop;
  end process;
end behavior;