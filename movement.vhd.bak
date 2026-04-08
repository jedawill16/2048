library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity movement_2048 is
  port(
    clk       : in  std_logic;
    reset_n   : in  std_logic;

    key_left  : in  std_logic;
    key_up    : in  std_logic;
    key_down  : in  std_logic;
    key_right : in  std_logic;

    cell00 : out std_logic_vector(3 downto 0);
    cell01 : out std_logic_vector(3 downto 0);
    cell02 : out std_logic_vector(3 downto 0);
    cell03 : out std_logic_vector(3 downto 0);
    cell10 : out std_logic_vector(3 downto 0);
    cell11 : out std_logic_vector(3 downto 0);
    cell12 : out std_logic_vector(3 downto 0);
    cell13 : out std_logic_vector(3 downto 0);
    cell20 : out std_logic_vector(3 downto 0);
    cell21 : out std_logic_vector(3 downto 0);
    cell22 : out std_logic_vector(3 downto 0);
    cell23 : out std_logic_vector(3 downto 0);
    cell30 : out std_logic_vector(3 downto 0);
    cell31 : out std_logic_vector(3 downto 0);
    cell32 : out std_logic_vector(3 downto 0);
    cell33 : out std_logic_vector(3 downto 0)
  );
end movement_2048;

architecture behavior of movement_2048 is

  subtype cell_t is unsigned(3 downto 0);
  type row_t   is array(0 to 3) of cell_t;
  type board_t is array(0 to 3) of row_t;

  signal board      : board_t := (others => (others => (others => '0')));
  signal rand_ctr   : unsigned(7 downto 0) := (others => '0');
  signal init_done  : std_logic := '0';

  signal prev_left  : std_logic := '1';
  signal prev_up    : std_logic := '1';
  signal prev_down  : std_logic := '1';
  signal prev_right : std_logic := '1';

  function boards_equal(a, b : board_t) return boolean is
  begin
    for r in 0 to 3 loop
      for c in 0 to 3 loop
        if a(r)(c) /= b(r)(c) then
          return false;
        end if;
      end loop;
    end loop;
    return true;
  end function;

  function has_empty(b : board_t) return boolean is
  begin
    for r in 0 to 3 loop
      for c in 0 to 3 loop
        if b(r)(c) = 0 then
          return true;
        end if;
      end loop;
    end loop;
    return false;
  end function;

  function compress_left(row_in : row_t) return row_t is
    variable temp : row_t := (others => (others => '0'));
    variable outp : row_t := (others => (others => '0'));
    variable idx  : integer := 0;
  begin
    for i in 0 to 3 loop
      if row_in(i) /= 0 then
        temp(idx) := row_in(i);
        idx := idx + 1;
      end if;
    end loop;

    outp := (others => (others => '0'));
    for i in 0 to 3 loop
      outp(i) := temp(i);
    end loop;

    return outp;
  end function;

  function reverse_row(row_in : row_t) return row_t is
    variable outp : row_t;
  begin
    outp(0) := row_in(3);
    outp(1) := row_in(2);
    outp(2) := row_in(1);
    outp(3) := row_in(0);
    return outp;
  end function;

  function move_left(b : board_t) return board_t is
    variable outp : board_t := b;
  begin
    for r in 0 to 3 loop
      outp(r) := compress_left(b(r));
    end loop;
    return outp;
  end function;

  function move_right(b : board_t) return board_t is
    variable outp : board_t := b;
    variable temp : row_t;
  begin
    for r in 0 to 3 loop
      temp    := reverse_row(b(r));
      temp    := compress_left(temp);
      outp(r) := reverse_row(temp);
    end loop;
    return outp;
  end function;

  function move_up(b : board_t) return board_t is
    variable outp : board_t := b;
    variable col  : row_t;
    variable temp : row_t;
  begin
    for c in 0 to 3 loop
      col(0) := b(0)(c);
      col(1) := b(1)(c);
      col(2) := b(2)(c);
      col(3) := b(3)(c);

      temp := compress_left(col);

      outp(0)(c) := temp(0);
      outp(1)(c) := temp(1);
      outp(2)(c) := temp(2);
      outp(3)(c) := temp(3);
    end loop;
    return outp;
  end function;

  function move_down(b : board_t) return board_t is
    variable outp : board_t := b;
    variable col  : row_t;
    variable temp : row_t;
  begin
    for c in 0 to 3 loop
      col(0) := b(3)(c);
      col(1) := b(2)(c);
      col(2) := b(1)(c);
      col(3) := b(0)(c);

      temp := compress_left(col);

      outp(3)(c) := temp(0);
      outp(2)(c) := temp(1);
      outp(1)(c) := temp(2);
      outp(0)(c) := temp(3);
    end loop;
    return outp;
  end function;

  function spawn_tile(b : board_t; seed : unsigned(7 downto 0)) return board_t is
    variable outp      : board_t := b;
    variable start_idx : integer := to_integer(seed(3 downto 0));
    variable idx       : integer;
    variable r, c      : integer;
  begin
    if not has_empty(b) then
      return outp;
    end if;

    for k in 0 to 15 loop
      idx := (start_idx + k) mod 16;
      r   := idx / 4;
      c   := idx mod 4;

      if outp(r)(c) = 0 then
        outp(r)(c) := to_unsigned(1, 4); -- value 2
        return outp;
      end if;
    end loop;

    return outp;
  end function;

begin

  process(clk, reset_n)
    variable next_board : board_t;
    variable moved      : boolean;
  begin
    if reset_n = '0' then
      board      <= (others => (others => (others => '0')));
      rand_ctr   <= (others => '0');
      init_done  <= '0';

      prev_left  <= '1';
      prev_up    <= '1';
      prev_down  <= '1';
      prev_right <= '1';

    elsif rising_edge(clk) then
      rand_ctr <= rand_ctr + 1;

      if init_done = '0' then
        next_board := (others => (others => (others => '0')));
        next_board := spawn_tile(next_board, rand_ctr);
        next_board := spawn_tile(next_board, rand_ctr + 5);
        board <= next_board;
        init_done <= '1';

      else
        next_board := board;
        moved := false;

        -- active-low buttons, one move per press
        if (key_left = '0' and prev_left = '1') then
          next_board := move_left(board);
          moved := not boards_equal(next_board, board);

        elsif (key_right = '0' and prev_right = '1') then
          next_board := move_right(board);
          moved := not boards_equal(next_board, board);

        elsif (key_up = '0' and prev_up = '1') then
          next_board := move_up(board);
          moved := not boards_equal(next_board, board);

        elsif (key_down = '0' and prev_down = '1') then
          next_board := move_down(board);
          moved := not boards_equal(next_board, board);
        end if;

        if moved then
          next_board := spawn_tile(next_board, rand_ctr);
        end if;

        board <= next_board;
      end if;

      prev_left  <= key_left;
      prev_up    <= key_up;
      prev_down  <= key_down;
      prev_right <= key_right;
    end if;
  end process;

  cell00 <= std_logic_vector(board(0)(0));
  cell01 <= std_logic_vector(board(0)(1));
  cell02 <= std_logic_vector(board(0)(2));
  cell03 <= std_logic_vector(board(0)(3));

  cell10 <= std_logic_vector(board(1)(0));
  cell11 <= std_logic_vector(board(1)(1));
  cell12 <= std_logic_vector(board(1)(2));
  cell13 <= std_logic_vector(board(1)(3));

  cell20 <= std_logic_vector(board(2)(0));
  cell21 <= std_logic_vector(board(2)(1));
  cell22 <= std_logic_vector(board(2)(2));
  cell23 <= std_logic_vector(board(2)(3));

  cell30 <= std_logic_vector(board(3)(0));
  cell31 <= std_logic_vector(board(3)(1));
  cell32 <= std_logic_vector(board(3)(2));
  cell33 <= std_logic_vector(board(3)(3));

end behavior;