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
    tile_value   : out std_logic_vector(63 downto 0);
    tile_x_bus   : out std_logic_vector(175 downto 0);
    tile_y_bus   : out std_logic_vector(175 downto 0)
  );
end board_manager;

architecture behavior of board_manager is
  constant BOARD_X   : integer := 252;
  constant BOARD_Y   : integer := 124;
  constant CELL_SIZE : integer := 120;
  constant GAP       : integer := 10;
  constant STEP_PIX  : integer := 10;

  subtype rc_t   is integer range 0 to 3;
  subtype val_t  is integer range 0 to 15;
  subtype slot_t is integer range 0 to 15;
  subtype x_t    is integer range 0 to 1023;
  subtype y_t    is integer range 0 to 767;

  type rc_array16  is array(0 to 15) of rc_t;
  type val_array16 is array(0 to 15) of val_t;
  type bit_array16 is array(0 to 15) of std_logic;
  type x_array16   is array(0 to 15) of x_t;
  type y_array16   is array(0 to 15) of y_t;

  component random_generation
    port(
      clk            : in  std_logic;
      reset          : in  std_logic;
      spawn_en       : in  std_logic;
      occupied_cells : in  std_logic_vector(15 downto 0);
      spawn_valid    : out std_logic;
      spawn_row      : out std_logic_vector(1 downto 0);
      spawn_col      : out std_logic_vector(1 downto 0);
      spawn_value    : out std_logic_vector(3 downto 0)
    );
  end component;

  signal active_s : bit_array16 := (
    0 => '1', 1 => '1',
    others => '0'
  );

  signal value_s : val_array16 := (
    0 => 1,  -- 2
    1 => 1,  -- 2
    others => 0
  );

  signal row_s : rc_array16 := (
    0 => 0,
    1 => 1,
    others => 0
  );

  signal col_s : rc_array16 := (
    0 => 0,
    1 => 2,
    others => 0
  );

  signal target_row_s : rc_array16 := (
    0 => 0,
    1 => 1,
    others => 0
  );

  signal target_col_s : rc_array16 := (
    0 => 0,
    1 => 2,
    others => 0
  );

  signal cur_x_s : x_array16 := (
    0 => BOARD_X + 0 * (CELL_SIZE + GAP),
    1 => BOARD_X + 2 * (CELL_SIZE + GAP),
    others => 0
  );

  signal cur_y_s : y_array16 := (
    0 => BOARD_Y + 0 * (CELL_SIZE + GAP),
    1 => BOARD_Y + 1 * (CELL_SIZE + GAP),
    others => 0
  );

  signal target_x_s : x_array16 := (
    0 => BOARD_X + 0 * (CELL_SIZE + GAP),
    1 => BOARD_X + 2 * (CELL_SIZE + GAP),
    others => 0
  );

  signal target_y_s : y_array16 := (
    0 => BOARD_Y + 0 * (CELL_SIZE + GAP),
    1 => BOARD_Y + 1 * (CELL_SIZE + GAP),
    others => 0
  );

  signal animating          : std_logic := '0';
  signal vs_prev            : std_logic := '0';

  signal occupied_cells_s   : std_logic_vector(15 downto 0);
  signal spawn_en_s         : std_logic := '0';
  signal spawn_after_commit : std_logic := '0';
  signal spawn_wait_s       : std_logic := '0';
  signal moved_pending_s    : std_logic := '0';

  signal spawn_valid_s      : std_logic;
  signal spawn_row_s        : std_logic_vector(1 downto 0);
  signal spawn_col_s        : std_logic_vector(1 downto 0);
  signal spawn_value_s      : std_logic_vector(3 downto 0);

begin

  U_RANDOM: random_generation
    port map(
      clk            => clk,
      reset          => reset,
      spawn_en       => spawn_en_s,
      occupied_cells => occupied_cells_s,
      spawn_valid    => spawn_valid_s,
      spawn_row      => spawn_row_s,
      spawn_col      => spawn_col_s,
      spawn_value    => spawn_value_s
    );

  process(active_s, row_s, col_s)
    variable occ : std_logic_vector(15 downto 0);
    variable idx : integer range 0 to 15;
  begin
    occ := (others => '0');

    for i in 0 to 15 loop
      if active_s(i) = '1' then
        idx := row_s(i) * 4 + col_s(i);
        occ(idx) := '1';
      end if;
    end loop;

    occupied_cells_s <= occ;
  end process;

  process(clk, reset)
    variable next_row_a : rc_array16;
    variable next_col_a : rc_array16;

    variable row_used   : integer range 0 to 4;
    variable col_used   : integer range 0 to 4;

    variable moved_any  : boolean;
    variable free_slot  : integer range -1 to 15;
    variable done_all   : boolean;
    variable sr         : integer range 0 to 3;
    variable sc         : integer range 0 to 3;

    variable occ        : std_logic_vector(15 downto 0);
    variable idx        : integer range 0 to 15;
  begin
    if reset = '1' then
      active_s <= (
        0 => '1', 1 => '1',
        others => '0'
      );

      value_s <= (
        0 => 1,
        1 => 1,
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

      animating          <= '0';
      vs_prev            <= '0';
      spawn_en_s         <= '0';
      spawn_after_commit <= '0';
      spawn_wait_s       <= '0';
      moved_pending_s    <= '0';

    elsif rising_edge(clk) then
      vs_prev    <= vert_sync;
      spawn_en_s <= '0';

      if spawn_after_commit = '1' then
        spawn_en_s         <= '1';
        spawn_after_commit <= '0';
        spawn_wait_s       <= '1';
      end if;

      if spawn_wait_s = '1' and spawn_valid_s = '1' then
        free_slot := -1;

        for i in 0 to 15 loop
          if active_s(i) = '0' and free_slot = -1 then
            free_slot := i;
          end if;
        end loop;

        if free_slot /= -1 then
          sr := to_integer(unsigned(spawn_row_s));
          sc := to_integer(unsigned(spawn_col_s));

          active_s(free_slot)     <= '1';
          value_s(free_slot)      <= to_integer(unsigned(spawn_value_s));
          row_s(free_slot)        <= sr;
          col_s(free_slot)        <= sc;
          target_row_s(free_slot) <= sr;
          target_col_s(free_slot) <= sc;

          cur_x_s(free_slot)      <= BOARD_X + sc * (CELL_SIZE + GAP);
          cur_y_s(free_slot)      <= BOARD_Y + sr * (CELL_SIZE + GAP);
          target_x_s(free_slot)   <= BOARD_X + sc * (CELL_SIZE + GAP);
          target_y_s(free_slot)   <= BOARD_Y + sr * (CELL_SIZE + GAP);
        end if;

        spawn_wait_s    <= '0';
        moved_pending_s <= '0';
      end if;

      if animating = '0' and spawn_wait_s = '0' and moved_pending_s = '0' then
        next_row_a := row_s;
        next_col_a := col_s;
        moved_any  := false;

        if move_left = '1' then
          for r in 0 to 3 loop
            row_used := 0;
            for c in 0 to 3 loop
              for k in 0 to 15 loop
                if active_s(k) = '1' and row_s(k) = r and col_s(k) = c then
                  next_row_a(k) := r;
                  next_col_a(k) := row_used;
                  row_used := row_used + 1;
                end if;
              end loop;
            end loop;
          end loop;

        elsif move_right = '1' then
          for r in 0 to 3 loop
            row_used := 0;
            for c in 3 downto 0 loop
              for k in 0 to 15 loop
                if active_s(k) = '1' and row_s(k) = r and col_s(k) = c then
                  next_row_a(k) := r;
                  next_col_a(k) := 3 - row_used;
                  row_used := row_used + 1;
                end if;
              end loop;
            end loop;
          end loop;

        elsif move_up = '1' then
          for c in 0 to 3 loop
            col_used := 0;
            for r in 0 to 3 loop
              for k in 0 to 15 loop
                if active_s(k) = '1' and row_s(k) = r and col_s(k) = c then
                  next_row_a(k) := col_used;
                  next_col_a(k) := c;
                  col_used := col_used + 1;
                end if;
              end loop;
            end loop;
          end loop;

        elsif move_down = '1' then
          for c in 0 to 3 loop
            col_used := 0;
            for r in 3 downto 0 loop
              for k in 0 to 15 loop
                if active_s(k) = '1' and row_s(k) = r and col_s(k) = c then
                  next_row_a(k) := 3 - col_used;
                  next_col_a(k) := c;
                  col_used := col_used + 1;
                end if;
              end loop;
            end loop;
          end loop;
        end if;

        for k in 0 to 15 loop
          if active_s(k) = '1' then
            if next_row_a(k) /= row_s(k) or next_col_a(k) /= col_s(k) then
              moved_any := true;
            end if;
          end if;
        end loop;

        if moved_any then
          target_row_s <= next_row_a;
          target_col_s <= next_col_a;

          for k in 0 to 15 loop
            target_x_s(k) <= BOARD_X + next_col_a(k) * (CELL_SIZE + GAP);
            target_y_s(k) <= BOARD_Y + next_row_a(k) * (CELL_SIZE + GAP);
          end loop;

          animating       <= '1';
          moved_pending_s <= '1';
        end if;
      end if;

      if (vs_prev = '0' and vert_sync = '1') then
        if animating = '1' then
          done_all := true;

          for i in 0 to 15 loop
            if active_s(i) = '1' then
              if cur_x_s(i) < target_x_s(i) then
                if cur_x_s(i) + STEP_PIX >= target_x_s(i) then
                  cur_x_s(i) <= target_x_s(i);
                else
                  cur_x_s(i) <= cur_x_s(i) + STEP_PIX;
                  done_all := false;
                end if;
              elsif cur_x_s(i) > target_x_s(i) then
                if cur_x_s(i) - STEP_PIX <= target_x_s(i) then
                  cur_x_s(i) <= target_x_s(i);
                else
                  cur_x_s(i) <= cur_x_s(i) - STEP_PIX;
                  done_all := false;
                end if;
              end if;

              if cur_y_s(i) < target_y_s(i) then
                if cur_y_s(i) + STEP_PIX >= target_y_s(i) then
                  cur_y_s(i) <= target_y_s(i);
                else
                  cur_y_s(i) <= cur_y_s(i) + STEP_PIX;
                  done_all := false;
                end if;
              elsif cur_y_s(i) > target_y_s(i) then
                if cur_y_s(i) - STEP_PIX <= target_y_s(i) then
                  cur_y_s(i) <= target_y_s(i);
                else
                  cur_y_s(i) <= cur_y_s(i) - STEP_PIX;
                  done_all := false;
                end if;
              end if;
            end if;
          end loop;

          if done_all then
            row_s <= target_row_s;
            col_s <= target_col_s;
            animating <= '0';

            if moved_pending_s = '1' then
              spawn_after_commit <= '1';
            end if;
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