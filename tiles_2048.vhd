library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tiles_2048 is
  port(
    pixel_row    : in  std_logic_vector(10 downto 0);
    pixel_column : in  std_logic_vector(10 downto 0);

    cell00 : in std_logic_vector(3 downto 0);
    cell01 : in std_logic_vector(3 downto 0);
    cell02 : in std_logic_vector(3 downto 0);
    cell03 : in std_logic_vector(3 downto 0);
    cell10 : in std_logic_vector(3 downto 0);
    cell11 : in std_logic_vector(3 downto 0);
    cell12 : in std_logic_vector(3 downto 0);
    cell13 : in std_logic_vector(3 downto 0);
    cell20 : in std_logic_vector(3 downto 0);
    cell21 : in std_logic_vector(3 downto 0);
    cell22 : in std_logic_vector(3 downto 0);
    cell23 : in std_logic_vector(3 downto 0);
    cell30 : in std_logic_vector(3 downto 0);
    cell31 : in std_logic_vector(3 downto 0);
    cell32 : in std_logic_vector(3 downto 0);
    cell33 : in std_logic_vector(3 downto 0);

    tile_on : out std_logic;
    Red     : out std_logic_vector(7 downto 0);
    Green   : out std_logic_vector(7 downto 0);
    Blue    : out std_logic_vector(7 downto 0)
  );
end tiles_2048;

architecture behavior of tiles_2048 is
  constant BOARD_X    : integer := 252;
  constant BOARD_Y    : integer := 124;
  constant CELL_SIZE  : integer := 120;
  constant GAP        : integer := 10;

  function get_cell_value(
    r : integer;
    c : integer;
    cell00, cell01, cell02, cell03,
    cell10, cell11, cell12, cell13,
    cell20, cell21, cell22, cell23,
    cell30, cell31, cell32, cell33 : std_logic_vector(3 downto 0)
  ) return std_logic_vector is
  begin
    if    (r = 0 and c = 0) then return cell00;
    elsif (r = 0 and c = 1) then return cell01;
    elsif (r = 0 and c = 2) then return cell02;
    elsif (r = 0 and c = 3) then return cell03;
    elsif (r = 1 and c = 0) then return cell10;
    elsif (r = 1 and c = 1) then return cell11;
    elsif (r = 1 and c = 2) then return cell12;
    elsif (r = 1 and c = 3) then return cell13;
    elsif (r = 2 and c = 0) then return cell20;
    elsif (r = 2 and c = 1) then return cell21;
    elsif (r = 2 and c = 2) then return cell22;
    elsif (r = 2 and c = 3) then return cell23;
    elsif (r = 3 and c = 0) then return cell30;
    elsif (r = 3 and c = 1) then return cell31;
    elsif (r = 3 and c = 2) then return cell32;
    else                         return cell33;
    end if;
  end function;

begin

  process(pixel_row, pixel_column,
          cell00, cell01, cell02, cell03,
          cell10, cell11, cell12, cell13,
          cell20, cell21, cell22, cell23,
          cell30, cell31, cell32, cell33)
    variable x, y      : integer;
    variable row_idx   : integer;
    variable col_idx   : integer;
    variable cell_x    : integer;
    variable cell_y    : integer;
    variable cell_val  : std_logic_vector(3 downto 0);
  begin
    x := to_integer(unsigned(pixel_column));
    y := to_integer(unsigned(pixel_row));

    tile_on <= '0';
    Red     <= (others => '0');
    Green   <= (others => '0');
    Blue    <= (others => '0');

    if (x >= BOARD_X) and (x < BOARD_X + 4 * CELL_SIZE + 3 * GAP) and
       (y >= BOARD_Y) and (y < BOARD_Y + 4 * CELL_SIZE + 3 * GAP) then

      col_idx := (x - BOARD_X) / (CELL_SIZE + GAP);
      row_idx := (y - BOARD_Y) / (CELL_SIZE + GAP);

      cell_x := (x - BOARD_X) mod (CELL_SIZE + GAP);
      cell_y := (y - BOARD_Y) mod (CELL_SIZE + GAP);

      if (col_idx >= 0 and col_idx <= 3 and row_idx >= 0 and row_idx <= 3) then
        if (cell_x < CELL_SIZE) and (cell_y < CELL_SIZE) then
          cell_val := get_cell_value(
            row_idx, col_idx,
            cell00, cell01, cell02, cell03,
            cell10, cell11, cell12, cell13,
            cell20, cell21, cell22, cell23,
            cell30, cell31, cell32, cell33
          );

          if cell_val /= "0000" then
            tile_on <= '1';

            -- all live tiles same gray for now
            Red   <= x"B8";
            Green <= x"B8";
            Blue  <= x"B8";
          end if;
        end if;
      end if;
    end if;
  end process;

end behavior;