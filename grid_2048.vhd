library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity grid_2048 is
  port(
    pixel_row    : in std_logic_vector(10 downto 0);
    pixel_column : in std_logic_vector(10 downto 0);
    Red          : out std_logic_vector(7 downto 0);
    Green        : out std_logic_vector(7 downto 0);
    Blue         : out std_logic_vector(7 downto 0)
  );
end grid_2048;

architecture behavior of grid_2048 is
  constant BOARD_X    : integer := 252;
  constant BOARD_Y    : integer := 124;
  constant CELL_SIZE  : integer := 120;
  constant GAP        : integer := 10;
  constant BOARD_SIZE : integer := 4 * CELL_SIZE + 3 * GAP;  -- 510
begin

  process(pixel_row, pixel_column)
    variable x, y : integer;
    variable row_idx, col_idx : integer;
    variable cell_x, cell_y : integer;
  begin
    x := to_integer(unsigned(pixel_column));
    y := to_integer(unsigned(pixel_row));

    -- screen background
    Red   <= x"FA";
    Green <= x"F8";
    Blue  <= x"EF";

    if (x >= BOARD_X) and (x < BOARD_X + BOARD_SIZE) and
       (y >= BOARD_Y) and (y < BOARD_Y + BOARD_SIZE) then

      -- board background
      Red   <= x"BB";
      Green <= x"AD";
      Blue  <= x"A0";

      col_idx := (x - BOARD_X) / (CELL_SIZE + GAP);
      row_idx := (y - BOARD_Y) / (CELL_SIZE + GAP);

      cell_x := (x - BOARD_X) mod (CELL_SIZE + GAP);
      cell_y := (y - BOARD_Y) mod (CELL_SIZE + GAP);

      -- draw the 16 empty cells
      if (col_idx >= 0 and col_idx <= 3 and row_idx >= 0 and row_idx <= 3) then
        if (cell_x < CELL_SIZE) and (cell_y < CELL_SIZE) then
          Red   <= x"CD";
          Green <= x"C1";
          Blue  <= x"B4";
        end if;
      end if;
    end if;
  end process;

end behavior;