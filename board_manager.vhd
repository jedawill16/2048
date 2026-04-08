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

  subtype cell_val_t is integer range 0 to 15;
  type board_t is array (0 to 3, 0 to 3) of cell_val_t;
  type line_t  is array (0 to 3) of integer range 0 to 15;

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

  signal board_s : board_t := (
    0 => (1, 0, 0, 0),
    1 => (0, 0, 1, 0),
    2 => (0, 0, 0, 0),
    3 => (0, 0, 0, 0)
  );

  signal occupied_cells_s : std_logic_vector(15 downto 0);
  signal spawn_en_s       : std_logic := '0';
  signal spawn_valid_s    : std_logic;
  signal spawn_row_s      : std_logic_vector(1 downto 0);
  signal spawn_col_s      : std_logic_vector(1 downto 0);
  signal spawn_value_s    : std_logic_vector(3 downto 0);

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

  process(board_s)
    variable occ : std_logic_vector(15 downto 0);
    variable idx : integer range 0 to 15;
  begin
    occ := (others => '0');

    for r in 0 to 3 loop
      for c in 0 to 3 loop
        idx := r * 4 + c;
        if board_s(r, c) /= 0 then
          occ(idx) := '1';
        else
          occ(idx) := '0';
        end if;
      end loop;
    end loop;

    occupied_cells_s <= occ;
  end process;

  process(clk, reset)
    variable b        : board_t;
    variable line_in  : line_t;
    variable line_out : line_t;
    variable changed  : boolean;
    variable merged   : boolean;
    variable wr       : integer range 0 to 4;
    variable sr       : integer range 0 to 3;
    variable sc       : integer range 0 to 3;
  begin
    if reset = '1' then
      board_s <= (
        0 => (1, 0, 0, 0),
        1 => (0, 0, 1, 0),
        2 => (0, 0, 0, 0),
        3 => (0, 0, 0, 0)
      );

      spawn_en_s <= '0';

    elsif rising_edge(clk) then
      spawn_en_s <= '0';
      b := board_s;
      changed := false;

      if move_left = '1' then
        for r in 0 to 3 loop
          for i in 0 to 3 loop
            line_in(i)  := b(r, i);
            line_out(i) := 0;
          end loop;

          wr := 0;
          merged := false;

          for i in 0 to 3 loop
            if line_in(i) /= 0 then
              if (wr > 0) and (line_out(wr-1) = line_in(i)) and (not merged) then
                line_out(wr-1) := line_out(wr-1) + 1;
                changed := true;
                merged := true;
              else
                if i /= wr then
                  changed := true;
                end if;
                line_out(wr) := line_in(i);
                wr := wr + 1;
                merged := false;
              end if;
            end if;
          end loop;

          for i in 0 to 3 loop
            b(r, i) := line_out(i);
          end loop;
        end loop;

      elsif move_right = '1' then
        for r in 0 to 3 loop
          for i in 0 to 3 loop
            line_in(i)  := b(r, 3 - i);
            line_out(i) := 0;
          end loop;

          wr := 0;
          merged := false;

          for i in 0 to 3 loop
            if line_in(i) /= 0 then
              if (wr > 0) and (line_out(wr-1) = line_in(i)) and (not merged) then
                line_out(wr-1) := line_out(wr-1) + 1;
                changed := true;
                merged := true;
              else
                if i /= wr then
                  changed := true;
                end if;
                line_out(wr) := line_in(i);
                wr := wr + 1;
                merged := false;
              end if;
            end if;
          end loop;

          for i in 0 to 3 loop
            b(r, 3 - i) := line_out(i);
          end loop;
        end loop;

      elsif move_up = '1' then
        for c in 0 to 3 loop
          for i in 0 to 3 loop
            line_in(i)  := b(i, c);
            line_out(i) := 0;
          end loop;

          wr := 0;
          merged := false;

          for i in 0 to 3 loop
            if line_in(i) /= 0 then
              if (wr > 0) and (line_out(wr-1) = line_in(i)) and (not merged) then
                line_out(wr-1) := line_out(wr-1) + 1;
                changed := true;
                merged := true;
              else
                if i /= wr then
                  changed := true;
                end if;
                line_out(wr) := line_in(i);
                wr := wr + 1;
                merged := false;
              end if;
            end if;
          end loop;

          for i in 0 to 3 loop
            b(i, c) := line_out(i);
          end loop;
        end loop;

      elsif move_down = '1' then
        for c in 0 to 3 loop
          for i in 0 to 3 loop
            line_in(i)  := b(3 - i, c);
            line_out(i) := 0;
          end loop;

          wr := 0;
          merged := false;

          for i in 0 to 3 loop
            if line_in(i) /= 0 then
              if (wr > 0) and (line_out(wr-1) = line_in(i)) and (not merged) then
                line_out(wr-1) := line_out(wr-1) + 1;
                changed := true;
                merged := true;
              else
                if i /= wr then
                  changed := true;
                end if;
                line_out(wr) := line_in(i);
                wr := wr + 1;
                merged := false;
              end if;
            end if;
          end loop;

          for i in 0 to 3 loop
            b(3 - i, c) := line_out(i);
          end loop;
        end loop;
      end if;

      if changed then
        board_s <= b;
        spawn_en_s <= '1';
      end if;

      if spawn_valid_s = '1' then
        sr := to_integer(unsigned(spawn_row_s));
        sc := to_integer(unsigned(spawn_col_s));

        if b(sr, sc) = 0 then
          b(sr, sc) := to_integer(unsigned(spawn_value_s));
          board_s <= b;
        end if;
      end if;
    end if;
  end process;

  process(board_s)
    variable a_bus : std_logic_vector(15 downto 0);
    variable v_bus : std_logic_vector(63 downto 0);
    variable x_bus : std_logic_vector(175 downto 0);
    variable y_bus : std_logic_vector(175 downto 0);
    variable idx   : integer range 0 to 15;
    variable xpos  : integer;
    variable ypos  : integer;
  begin
    a_bus := (others => '0');
    v_bus := (others => '0');
    x_bus := (others => '0');
    y_bus := (others => '0');

    for r in 0 to 3 loop
      for c in 0 to 3 loop
        idx := r * 4 + c;
        xpos := BOARD_X + c * (CELL_SIZE + GAP);
        ypos := BOARD_Y + r * (CELL_SIZE + GAP);

        if board_s(r, c) /= 0 then
          a_bus(idx) := '1';
        else
          a_bus(idx) := '0';
        end if;

        v_bus(idx*4+3 downto idx*4) := std_logic_vector(to_unsigned(board_s(r, c), 4));
        x_bus(idx*11+10 downto idx*11) := std_logic_vector(to_unsigned(xpos, 11));
        y_bus(idx*11+10 downto idx*11) := std_logic_vector(to_unsigned(ypos, 11));
      end loop;
    end loop;

    tile_active <= a_bus;
    tile_value  <= v_bus;
    tile_x_bus  <= x_bus;
    tile_y_bus  <= y_bus;
  end process;

end behavior;