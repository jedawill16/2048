library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity movement is
  port(
    clk        : in  std_logic;
    reset      : in  std_logic;
    key_left   : in  std_logic;
    key_up     : in  std_logic;
    key_down   : in  std_logic;
    key_right  : in  std_logic;
    move_left  : out std_logic;
    move_up    : out std_logic;
    move_down  : out std_logic;
    move_right : out std_logic
  );
end movement;

architecture behavior of movement is
  signal left_prev, up_prev, down_prev, right_prev : std_logic := '1';
begin
  process(clk, reset)
  begin
    if reset = '1' then
      left_prev  <= '1';
      up_prev    <= '1';
      down_prev  <= '1';
      right_prev <= '1';
      move_left  <= '0';
      move_up    <= '0';
      move_down  <= '0';
      move_right <= '0';

    elsif rising_edge(clk) then
      move_left  <= '0';
      move_up    <= '0';
      move_down  <= '0';
      move_right <= '0';

      if (left_prev = '1' and key_left = '0') then
        move_left <= '1';
      end if;

      if (up_prev = '1' and key_up = '0') then
        move_up <= '1';
      end if;

      if (down_prev = '1' and key_down = '0') then
        move_down <= '1';
      end if;

      if (right_prev = '1' and key_right = '0') then
        move_right <= '1';
      end if;

      left_prev  <= key_left;
      up_prev    <= key_up;
      down_prev  <= key_down;
      right_prev <= key_right;
    end if;
  end process;
end behavior;