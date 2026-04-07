library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
-- BOARD: stores the 4x4 grid of tiles and values 
-- Using 4 bits per tile supports values up to 2^11 = 2048
entity BOARD is
    port (
        CLOCK      : in  std_logic;
        RESET      : in  std_logic;
        WRITE_EN   : in  std_logic;
        --new board state written by move/merge logic
        BOARD_IN   : in  std_logic_vector(63 downto 0);  -- 16 tiles x 4 bits
        --current board state read by VGA display and move logic
        BOARD_OUT  : out std_logic_vector(63 downto 0)
    );
end BOARD;
 
architecture Behavioral of BOARD is
 
    signal board_reg : std_logic_vector(63 downto 0) := (others => '0');
 
begin
 
    process(CLOCK)
    begin
        if rising_edge(CLOCK) then
            if RESET = '1' then
                board_reg <= (others => '0');
            elsif WRITE_EN = '1' then
                board_reg <= BOARD_IN;
            end if;
        end if;
    end process;
 
    BOARD_OUT <= board_reg;
 
end Behavioral;