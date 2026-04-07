library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
-- top-level module; connects input handler, control FSM, board logic, and VGA display
entity GAME_2048 is
    port (
        CLOCK_50   : in  std_logic;                      -- 50 MHz system clock
        KEY        : in  std_logic_vector(3 downto 0);   -- Push buttons (active low)
        VGA_R      : out std_logic_vector(7 downto 0);
        VGA_G      : out std_logic_vector(7 downto 0);
        VGA_B      : out std_logic_vector(7 downto 0);
        VGA_HS     : out std_logic;
        VGA_VS     : out std_logic;
        VGA_BLANK_N: out std_logic;
        VGA_SYNC_N : out std_logic;
        VGA_CLK    : out std_logic
    );
end GAME_2048;
 
architecture Structural of GAME_2048 is
 
    -- task: declare internal signals connecting submodules
    -- e.g. board state, move direction, VGA pixel coordinates
 
begin
 
    -- task: create submodules:
    --   INPUT_HANDLER
    --   CONTROL_FSM
    --   BOARD
    --   MOVE_LOGIC
    --   TILE_GEN
    --   VGA_DISPLAY
    --   VGA_SYNC
 
end Structural;