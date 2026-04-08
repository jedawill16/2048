library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_SYNC_module is
  port(
    clock_50Mhz : in  std_logic;
    red, green, blue : in  std_logic_vector(7 downto 0);
    red_out, green_out, blue_out : out std_logic_vector(7 downto 0);
    horiz_sync_out, vert_sync_out, video_on, pixel_clock : out std_logic;
    pixel_row, pixel_column : out std_logic_vector(10 downto 0)
  );
end VGA_SYNC_module;

architecture a of VGA_SYNC_module is
  signal horiz_sync, vert_sync, pixel_clock_int : std_logic := '1';
  signal video_on_int, video_on_v, video_on_h : std_logic := '0';
  signal h_count, v_count : unsigned(10 downto 0) := (others => '0');

  constant H_pixels_across : natural := 1024;
  constant H_sync_low      : natural := 1032;
  constant H_sync_high     : natural := 1176;
  constant H_end_count     : natural := 1344;

  constant V_pixels_down   : natural := 768;
  constant V_sync_low      : natural := 771;
  constant V_sync_high     : natural := 777;
  constant V_end_count     : natural := 806;

  component video_PLL
    port
    (
      inclk0 : in  std_logic := '0';
      c0     : out std_logic
    );
  end component;
begin

  video_PLL_inst : video_PLL
    port map (
      inclk0 => clock_50Mhz,
      c0     => pixel_clock_int
    );

  video_on_int <= video_on_h and video_on_v;
  pixel_clock  <= pixel_clock_int;
  video_on     <= video_on_int;

  process(pixel_clock_int)
  begin
    if rising_edge(pixel_clock_int) then

      if h_count = to_unsigned(H_end_count, h_count'length) then
        h_count <= (others => '0');
      else
        h_count <= h_count + 1;
      end if;

      if (h_count >= to_unsigned(H_sync_low, h_count'length)) and
         (h_count <= to_unsigned(H_sync_high, h_count'length)) then
        horiz_sync <= '0';
      else
        horiz_sync <= '1';
      end if;

      if (v_count >= to_unsigned(V_end_count, v_count'length)) and
         (h_count >= to_unsigned(H_sync_low, h_count'length)) then
        v_count <= (others => '0');
      elsif h_count = to_unsigned(H_sync_low, h_count'length) then
        v_count <= v_count + 1;
      end if;

      if (v_count >= to_unsigned(V_sync_low, v_count'length)) and
         (v_count <= to_unsigned(V_sync_high, v_count'length)) then
        vert_sync <= '0';
      else
        vert_sync <= '1';
      end if;

      if h_count < to_unsigned(H_pixels_across, h_count'length) then
        video_on_h   <= '1';
        pixel_column <= std_logic_vector(h_count);
      else
        video_on_h   <= '0';
        pixel_column <= (others => '0');
      end if;

      if v_count < to_unsigned(V_pixels_down, v_count'length) then
        video_on_v <= '1';
        pixel_row  <= std_logic_vector(v_count);
      else
        video_on_v <= '0';
        pixel_row  <= (others => '0');
      end if;

      horiz_sync_out <= horiz_sync;
      vert_sync_out  <= vert_sync;

      if video_on_int = '1' then
        red_out   <= red;
        green_out <= green;
        blue_out  <= blue;
      else
        red_out   <= (others => '0');
        green_out <= (others => '0');
        blue_out  <= (others => '0');
      end if;
    end if;
  end process;

end a;