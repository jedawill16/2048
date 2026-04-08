library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity board_manager is
  port(
    clk          : in  std_logic;
    reset        : in  std_logic;
    vert_sync    : in  std_logic;

    move_left    : in  std_logic;
    move_up      : in  std_logic;
    move_down    : in  std_logic;
    move_right   : in  std_logic;

    tile_active  : out std_logic_vector(15 downto 0);
    tile_value   : out std_logic_vector(63 downto 0);   -- 16 tiles * 4 bits
    tile_x_bus   : out std_logic_vector(175 downto 0);  -- 16 tiles * 11 bits
    tile_y_bus   : out std_logic_vector(175 downto 0)   -- 16 tiles * 11 bits
  );
end board_manager;

architecture behavior of board_manager is
  constant BOARD_X    : integer := 252;
  constant BOARD_Y    : integer := 124;
  constant CELL_SIZE  : integer := 120;
  constant GAP        : integer := 10;
  constant STEP_PIX   : integer := 10;

  type int_array16 is array(0 to 15) of integer;
  type val_array16 is array(0 to 15) of integer range 0 to 15;
  type bit_array16 is array(0 to 15) of std_logic;

  signal active_s      : bit_array16 := (
    0 => '1', 1 => '1',
    others => '0'
  );

  signal value_s       : val_array16 := (
    0 => 1,   -- 2
    1 => 2,   -- 4
    others => 0
  );

  signal row_s         : int_array16 := (
    0 => 0,
    1 => 1,
    others => 0
  );

  signal col_s         : int_array16 := (
    0 => 0,
    1 => 2,
    others => 0
  );

  signal target_row_s  : int_array16 := (others => 0);
  signal target_col_s  : int_array16 := (others => 0);

  signal cur_x_s       : int_array16 := (
    0 => BOARD_X + 0 * (CELL_SIZE + GAP),
    1 => BOARD_X + 2 * (CELL_SIZE + GAP),
    others => 0
  );

  signal cur_y_s       : int_array16 := (
    0 => BOARD_Y + 0 * (CELL_SIZE + GAP),
    1 => BOARD_Y + 1 * (CELL_SIZE + GAP),
    others => 0
  );

  signal target_x_s    : int_array16 := (
    0 => BOARD_X + 0 * (CELL_SIZE + GAP),
    1 => BOARD_X + 2 * (CELL_SIZE + GAP),
    others => 0
  );

  signal target_y_s    : int_array16 := (
    0 => BOARD_Y + 0 * (CELL_SIZE + GAP),
    1 => BOARD_Y + 1 * (CELL_SIZE + GAP),
    others => 0
  );

  signal animating     : std_logic := '0';
  signal vs_prev       : std_logic := '0';

begin

  process(clk, reset)
    variable next_col   : integer;
    variable next_row   : integer;
    variable found      : boolean;
    variable idx        : integer;
    variable all_done   : boolean;
    variable new_tr     : int_array16;
    variable new_tc     : int_array16;
  begin
    if reset = '1' then
      active_s <= (
        0 => '1', 1 => '1',
        others => '0'
      );

      value_s <= (
        0 => 1,
        1 => 2,
        others => 0
      );

      row_s <= (
        0 => 0,
        1 => 1,
        others => 0
      );

      col_s <= (
        0 => 0,
        1 => 2,
        others => 0
      );

      target_row_s <= (
        0 => 0,
        1 => 1,
        others => 0
      );

      target_col_s <= (
        0 => 0,
        1 => 2,
        others => 0
      );

      cur_x_s <= (
        0 => BOARD_X + 0 * (CELL_SIZE + GAP),
        1 => BOARD_X + 2 * (CELL_SIZE + GAP),
        others => 0
      );

      cur_y_s <= (
        0 => BOARD_Y + 0 * (CELL_SIZE + GAP),
        1 => BOARD_Y + 1 * (CELL_SIZE + GAP),
        others => 0
      );

      target_x_s <= (
        0 => BOARD_X + 0 * (CELL_SIZE + GAP),
        1 => BOARD_X + 2 * (CELL_SIZE + GAP),
        others => 0
      );

      target_y_s <= (
        0 => BOARD_Y + 0 * (CELL_SIZE + GAP),
        1 => BOARD_Y + 1 * (CELL_SIZE + GAP),
        others => 0
      );

      animating <= '0';
      vs_prev   <= '0';

    elsif rising_edge(clk) then
      vs_prev <= vert_sync;

      -- start a move only if not already animating
      if animating = '0' then
        new_tr := row_s;
        new_tc := col_s;

        if move_left = '1' then
          for r in 0 to 3 loop
            next_col := 0;
            for c in 0 to 3 loop
              found := false;
              idx := 0;
              for i in 0 to 15 loop
                if active_s(i) = '1' and row_s(i) = r and col_s(i) = c then
                  found := true;
                  idx := i;
                end if;
              end loop;
              if found then
                new_tr(idx) := r;
                new_tc(idx) := next_col;
                next_col := next_col + 1;
              end if;
            end loop;
          end loop;

        elsif move_right = '1' then
          for r in 0 to 3 loop
            next_col := 3;
            for c in 3 downto 0 loop
              found := false;
              idx := 0;
              for i in 0 to 15 loop
                if active_s(i) = '1' and row_s(i) = r and col_s(i) = c then
                  found := true;
                  idx := i;
                end if;
              end loop;
              if found then
                new_tr(idx) := r;
                new_tc(idx) := next_col;
                next_col := next_col - 1;
              end if;
            end loop;
          end loop;

        elsif move_up = '1' then
          for c in 0 to 3 loop
            next_row := 0;
            for r in 0 to 3 loop
              found := false;
              idx := 0;
              for i in 0 to 15 loop
                if active_s(i) = '1' and row_s(i) = r and col_s(i) = c then
                  found := true;
                  idx := i;
                end if;
              end loop;
              if found then
                new_tr(idx) := next_row;
                new_tc(idx) := c;
                next_row := next_row + 1;
              end if;
            end loop;
          end loop;

        elsif move_down = '1' then
          for c in 0 to 3 loop
            next_row := 3;
            for r in 3 downto 0 loop
              found := false;
              idx := 0;
              for i in 0 to 15 loop
                if active_s(i) = '1' and row_s(i) = r and col_s(i) = c then
                  found := true;
                  idx := i;
                end if;
              end loop;
              if found then
                new_tr(idx) := next_row;
                new_tc(idx) := c;
                next_row := next_row - 1;
              end if;
            end loop;
          end loop;
        end if;

        target_row_s <= new_tr;
        target_col_s <= new_tc;

        for i in 0 to 15 loop
          target_x_s(i) <= BOARD_X + new_tc(i) * (CELL_SIZE + GAP);
          target_y_s(i) <= BOARD_Y + new_tr(i) * (CELL_SIZE + GAP);
        end loop;

        -- check whether any tile actually moves
        all_done := true;
        for i in 0 to 15 loop
          if active_s(i) = '1' then
            if (BOARD_X + new_tc(i) * (CELL_SIZE + GAP) /= cur_x_s(i)) or
               (BOARD_Y + new_tr(i) * (CELL_SIZE + GAP) /= cur_y_s(i)) then
              all_done := false;
            end if;
          end if;
        end loop;

        if all_done = false then
          animating <= '1';
        end if;
      end if;

      -- animate once per frame
      if (vs_prev = '0' and vert_sync = '1') then
        if animating = '1' then
          all_done := true;

          for i in 0 to 15 loop
            if active_s(i) = '1' then

              if cur_x_s(i) < target_x_s(i) then
                if cur_x_s(i) + STEP_PIX >= target_x_s(i) then
                  cur_x_s(i) <= target_x_s(i);
                else
                  cur_x_s(i) <= cur_x_s(i) + STEP_PIX;
                end if;
              elsif cur_x_s(i) > target_x_s(i) then
                if cur_x_s(i) - STEP_PIX <= target_x_s(i) then
                  cur_x_s(i) <= target_x_s(i);
                else
                  cur_x_s(i) <= cur_x_s(i) - STEP_PIX;
                end if;
              end if;

              if cur_y_s(i) < target_y_s(i) then
                if cur_y_s(i) + STEP_PIX >= target_y_s(i) then
                  cur_y_s(i) <= target_y_s(i);
                else
                  cur_y_s(i) <= cur_y_s(i) + STEP_PIX;
                end if;
              elsif cur_y_s(i) > target_y_s(i) then
                if cur_y_s(i) - STEP_PIX <= target_y_s(i) then
                  cur_y_s(i) <= target_y_s(i);
                else
                  cur_y_s(i) <= cur_y_s(i) - STEP_PIX;
                end if;
              end if;
            end if;
          end loop;

          for i in 0 to 15 loop
            if active_s(i) = '1' then
              if (cur_x_s(i) /= target_x_s(i)) or (cur_y_s(i) /= target_y_s(i)) then
                all_done := false;
              end if;
            end if;
          end loop;

          if all_done then
            row_s <= target_row_s;
            col_s <= target_col_s;
            animating <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  process(active_s, value_s, cur_x_s, cur_y_s)
    variable a_bus : std_logic_vector(15 downto 0);
    variable v_bus : std_logic_vector(63 downto 0);
    variable x_bus : std_logic_vector(175 downto 0);
    variable y_bus : std_logic_vector(175 downto 0);
  begin
    a_bus := (others => '0');
    v_bus := (others => '0');
    x_bus := (others => '0');
    y_bus := (others => '0');

    for i in 0 to 15 loop
      a_bus(i) := active_s(i);
      v_bus(i*4+3 downto i*4) := std_logic_vector(to_unsigned(value_s(i), 4));
      x_bus(i*11+10 downto i*11) := std_logic_vector(to_unsigned(cur_x_s(i), 11));
      y_bus(i*11+10 downto i*11) := std_logic_vector(to_unsigned(cur_y_s(i), 11));
    end loop;

    tile_active <= a_bus;
    tile_value  <= v_bus;
    tile_x_bus  <= x_bus;
    tile_y_bus  <= y_bus;
  end process;

end behavior;