library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DE2_115_TOP is
  generic (
    TICKS_PER_SECOND : natural := 50_000_000  -- default for 50 MHz CLOCK_50
  );

  port (
    -- Clocks
    CLOCK_50   : in std_logic;
    CLOCK2_50  : in std_logic;
    CLOCK3_50  : in std_logic;
    SMA_CLKIN  : in std_logic;
    SMA_CLKOUT : out std_logic;

    -- Buttons and switches
    KEY : in std_logic_vector(3 downto 0);
    SW  : in std_logic_vector(17 downto 0);

    -- LED displays
    HEX0 : out std_logic_vector(6 downto 0);
    HEX1 : out std_logic_vector(6 downto 0);
    HEX2 : out std_logic_vector(6 downto 0);
    HEX3 : out std_logic_vector(6 downto 0);
    HEX4 : out std_logic_vector(6 downto 0);
    HEX5 : out std_logic_vector(6 downto 0);
    HEX6 : out std_logic_vector(6 downto 0);
    HEX7 : out std_logic_vector(6 downto 0);
    LEDG : out std_logic_vector(8 downto 0);
    LEDR : out std_logic_vector(17 downto 0);

    -- RS-232 interface
    UART_CTS : out std_logic;
    UART_RTS : in std_logic;
    UART_RXD : in std_logic;
    UART_TXD : out std_logic;

    -- LCD Module
    LCD_BLON : out std_logic;
    LCD_EN   : out std_logic;
    LCD_ON   : out std_logic;
    LCD_RS   : out std_logic;
    LCD_RW   : out std_logic;
    LCD_DATA : inout std_logic_vector(7 downto 0);

    -- PS/2 ports
    PS2_CLK  : inout std_logic;
    PS2_DAT  : inout std_logic;
    PS2_CLK2 : inout std_logic;
    PS2_DAT2 : inout std_logic;

    -- VGA output
    VGA_BLANK_N : out std_logic;
    VGA_CLK     : out std_logic;
    VGA_HS      : out std_logic;
    VGA_SYNC_N  : out std_logic;
    VGA_VS      : out std_logic;
    VGA_R       : out std_logic_vector(7 downto 0);
    VGA_G       : out std_logic_vector(7 downto 0);
    VGA_B       : out std_logic_vector(7 downto 0);

    -- SRAM
    SRAM_ADDR : out unsigned(19 downto 0);
    SRAM_DQ   : inout unsigned(15 downto 0);
    SRAM_CE_N : out std_logic;
    SRAM_LB_N : out std_logic;
    SRAM_OE_N : out std_logic;
    SRAM_UB_N : out std_logic;
    SRAM_WE_N : out std_logic;

    -- Audio CODEC
    AUD_ADCDAT  : in std_logic;
    AUD_ADCLRCK : inout std_logic;
    AUD_BCLK    : inout std_logic;
    AUD_DACDAT  : out std_logic;
    AUD_DACLRCK : inout std_logic;
    AUD_XCK     : out std_logic
  );
end DE2_115_TOP;

architecture structural of DE2_115_TOP is

  component VGA_SYNC_module
    port(
      clock_50Mhz : in  std_logic;
      red, green, blue : in  std_logic_vector(7 downto 0);
      red_out, green_out, blue_out : out std_logic_vector(7 downto 0);
      horiz_sync_out, vert_sync_out, video_on, pixel_clock : out std_logic;
      pixel_row, pixel_column : out std_logic_vector(10 downto 0)
    );
  end component;

  component grid_2048
    port(
      pixel_row    : in std_logic_vector(10 downto 0);
      pixel_column : in std_logic_vector(10 downto 0);
      Red          : out std_logic_vector(7 downto 0);
      Green        : out std_logic_vector(7 downto 0);
      Blue         : out std_logic_vector(7 downto 0)
    );
  end component;
  
  component tiles_2048
  port(
    pixel_row    : in  std_logic_vector(10 downto 0);
    pixel_column : in  std_logic_vector(10 downto 0);
    tile_on      : out std_logic;
    Red          : out std_logic_vector(7 downto 0);
    Green        : out std_logic_vector(7 downto 0);
    Blue         : out std_logic_vector(7 downto 0)
  );
end component;

  signal red_int, green_int, blue_int : std_logic_vector(7 downto 0);
  signal vga_r_int, vga_g_int, vga_b_int : std_logic_vector(7 downto 0);
  signal horiz_sync_int, vert_sync_int : std_logic;
  signal pixel_row_int, pixel_column_int : std_logic_vector(10 downto 0);

  signal grid_r, grid_g, grid_b : std_logic_vector(7 downto 0);
  signal tile_r, tile_g, tile_b : std_logic_vector(7 downto 0);
  signal tile_on_int : std_logic;
  
begin

  VGA_HS <= horiz_sync_int;
  VGA_VS <= vert_sync_int;
  VGA_R  <= vga_r_int;
  VGA_G  <= vga_g_int;
  VGA_B  <= vga_b_int;
  VGA_SYNC_N <= '1';

  U1: VGA_SYNC_module
    port map(
      clock_50Mhz    => CLOCK_50,
      red            => red_int,
      green          => green_int,
      blue           => blue_int,
      red_out        => vga_r_int,
      green_out      => vga_g_int,
      blue_out       => vga_b_int,
      horiz_sync_out => horiz_sync_int,
      vert_sync_out  => vert_sync_int,
      video_on       => VGA_BLANK_N,
      pixel_clock    => VGA_CLK,
      pixel_row      => pixel_row_int,
      pixel_column   => pixel_column_int
    );

  U2: grid_2048
    port map(
      pixel_row    => pixel_row_int,
      pixel_column => pixel_column_int,
      Red          => grid_r,
      Green        => grid_g,
      Blue         => grid_b
    );
	 
	U3: tiles_2048
	  port map(
		 pixel_row    => pixel_row_int,
		 pixel_column => pixel_column_int,
		 tile_on      => tile_on_int,
		 Red          => tile_r,
		 Green        => tile_g,
		 Blue         => tile_b
	  );
	  
  red_int   <= tile_r when tile_on_int = '1' else grid_r;
  green_int <= tile_g when tile_on_int = '1' else grid_g;
  blue_int  <= tile_b when tile_on_int = '1' else grid_b;

end structural;