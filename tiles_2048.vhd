library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tiles_2048 is
  port(
    pixel_row    : in  std_logic_vector(10 downto 0);
    pixel_column : in  std_logic_vector(10 downto 0);

    tile_active  : in  std_logic_vector(15 downto 0);
    tile_value   : in  std_logic_vector(63 downto 0);
    tile_x_bus   : in  std_logic_vector(175 downto 0);
    tile_y_bus   : in  std_logic_vector(175 downto 0);

    tile_on      : out std_logic;
    Red          : out std_logic_vector(7 downto 0);
    Green        : out std_logic_vector(7 downto 0);
    Blue         : out std_logic_vector(7 downto 0)
  );
end tiles_2048;

architecture behavior of tiles_2048 is
  constant CELL_SIZE : integer := 120;

  function digit_to_seg(d : integer) return std_logic_vector is
    -- seg order: a b c d e f g
  begin
    case d is
      when 0 => return "1111110";
      when 1 => return "0110000";
      when 2 => return "1101101";
      when 3 => return "1111001";
      when 4 => return "0110011";
      when 5 => return "1011011";
      when 6 => return "1011111";
      when 7 => return "1110000";
      when 8 => return "1111111";
      when 9 => return "1111011";
      when others => return "0000001";
    end case;
  end function;
begin
  process(pixel_row, pixel_column, tile_active, tile_value, tile_x_bus, tile_y_bus)
    variable x, y      : integer;
    variable tx, ty    : integer;
    variable val       : integer;
    variable hit       : boolean;

    variable actual_num : integer;
    variable num_digits : integer;
    variable d0, d1, d2, d3 : integer;
    variable left_x     : integer;
    variable top_y      : integer;
    variable digit_w    : integer;
    variable digit_h    : integer;
    variable digit_gap  : integer;
    variable total_w    : integer;
    variable local_x    : integer;
    variable local_y    : integer;
    variable digit_idx  : integer;
    variable digit_val  : integer;
    variable segs       : std_logic_vector(6 downto 0);
    variable on_digit   : boolean;
    variable seg_on     : boolean;
    variable thick      : integer;

    variable base_r, base_g, base_b : std_logic_vector(7 downto 0);
    variable text_r, text_g, text_b : std_logic_vector(7 downto 0);
  begin
    x := to_integer(unsigned(pixel_column));
    y := to_integer(unsigned(pixel_row));

    tile_on <= '0';
    Red     <= (others => '0');
    Green   <= (others => '0');
    Blue    <= (others => '0');

    hit := false;

    for i in 0 to 15 loop
      tx  := to_integer(unsigned(tile_x_bus(i*11+10 downto i*11)));
      ty  := to_integer(unsigned(tile_y_bus(i*11+10 downto i*11)));
      val := to_integer(unsigned(tile_value(i*4+3 downto i*4)));

      if tile_active(i) = '1' then
        if (x >= tx) and (x < tx + CELL_SIZE) and
           (y >= ty) and (y < ty + CELL_SIZE) and
           (not hit) then

          tile_on <= '1';
          hit := true;

          -- tile color
          case val is
            when 1  => base_r := x"FF"; base_g := x"00"; base_b := x"00"; -- 2
            when 2  => base_r := x"FF"; base_g := x"88"; base_b := x"00"; -- 4
            when 3  => base_r := x"FF"; base_g := x"FF"; base_b := x"00"; -- 8
            when 4  => base_r := x"99"; base_g := x"FF"; base_b := x"00"; -- 16
            when 5  => base_r := x"00"; base_g := x"AA"; base_b := x"00"; -- 32
            when 6  => base_r := x"66"; base_g := x"CC"; base_b := x"FF"; -- 64
            when 7  => base_r := x"00"; base_g := x"44"; base_b := x"CC"; -- 128
            when 8  => base_r := x"88"; base_g := x"00"; base_b := x"CC"; -- 256
            when 9  => base_r := x"FF"; base_g := x"00"; base_b := x"AA"; -- 512
            when 10 => base_r := x"FF"; base_g := x"CC"; base_b := x"DD"; -- 1024
            when others =>
              base_r := x"FF"; base_g := x"FF"; base_b := x"FF"; -- 2048+
          end case;

          -- default tile fill
          Red   <= base_r;
          Green <= base_g;
          Blue  <= base_b;

          -- text color
          text_r := x"22";
          text_g := x"22";
          text_b := x"22";

          -- convert encoded value to actual displayed number
          case val is
            when 1  => actual_num := 2;
            when 2  => actual_num := 4;
            when 3  => actual_num := 8;
            when 4  => actual_num := 16;
            when 5  => actual_num := 32;
            when 6  => actual_num := 64;
            when 7  => actual_num := 128;
            when 8  => actual_num := 256;
            when 9  => actual_num := 512;
            when 10 => actual_num := 1024;
            when others => actual_num := 2048;
          end case;

          -- split into digits
          if actual_num < 10 then
            num_digits := 1;
            d0 := actual_num;
            d1 := 0;
            d2 := 0;
            d3 := 0;
          elsif actual_num < 100 then
            num_digits := 2;
            d0 := actual_num / 10;
            d1 := actual_num mod 10;
            d2 := 0;
            d3 := 0;
          elsif actual_num < 1000 then
            num_digits := 3;
            d0 := actual_num / 100;
            d1 := (actual_num / 10) mod 10;
            d2 := actual_num mod 10;
            d3 := 0;
          else
            num_digits := 4;
            d0 := actual_num / 1000;
            d1 := (actual_num / 100) mod 10;
            d2 := (actual_num / 10) mod 10;
            d3 := actual_num mod 10;
          end if;

          -- choose digit size based on how many digits
          if num_digits = 1 then
            digit_w   := 28;
            digit_h   := 48;
            digit_gap := 6;
            thick     := 6;
          elsif num_digits = 2 then
            digit_w   := 24;
            digit_h   := 42;
            digit_gap := 5;
            thick     := 5;
          elsif num_digits = 3 then
            digit_w   := 18;
            digit_h   := 34;
            digit_gap := 4;
            thick     := 4;
          else
            digit_w   := 15;
            digit_h   := 28;
            digit_gap := 3;
            thick     := 3;
          end if;

          total_w := num_digits * digit_w + (num_digits - 1) * digit_gap;
          left_x  := tx + (CELL_SIZE - total_w) / 2;
          top_y   := ty + (CELL_SIZE - digit_h) / 2;

          on_digit := false;
          seg_on   := false;

          if (x >= left_x) and (x < left_x + total_w) and
             (y >= top_y) and (y < top_y + digit_h) then

            digit_idx := (x - left_x) / (digit_w + digit_gap);

            if digit_idx < num_digits then
              local_x := (x - left_x) - digit_idx * (digit_w + digit_gap);
              local_y := y - top_y;

              if local_x >= 0 and local_x < digit_w then
                on_digit := true;

                case digit_idx is
                  when 0 => digit_val := d0;
                  when 1 => digit_val := d1;
                  when 2 => digit_val := d2;
                  when others => digit_val := d3;
                end case;

                segs := digit_to_seg(digit_val);

                -- 7-segment blocks
                -- a
                if (segs(6) = '1') and
                   (local_y >= 0) and (local_y < thick) and
                   (local_x >= thick/2) and (local_x < digit_w - thick/2) then
                  seg_on := true;
                end if;

                -- b
                if (segs(5) = '1') and
                   (local_x >= digit_w - thick) and (local_x < digit_w) and
                   (local_y >= thick/2) and (local_y < digit_h/2 - 1) then
                  seg_on := true;
                end if;

                -- c
                if (segs(4) = '1') and
                   (local_x >= digit_w - thick) and (local_x < digit_w) and
                   (local_y >= digit_h/2) and (local_y < digit_h - thick/2) then
                  seg_on := true;
                end if;

                -- d
                if (segs(3) = '1') and
                   (local_y >= digit_h - thick) and (local_y < digit_h) and
                   (local_x >= thick/2) and (local_x < digit_w - thick/2) then
                  seg_on := true;
                end if;

                -- e
                if (segs(2) = '1') and
                   (local_x >= 0) and (local_x < thick) and
                   (local_y >= digit_h/2) and (local_y < digit_h - thick/2) then
                  seg_on := true;
                end if;

                -- f
                if (segs(1) = '1') and
                   (local_x >= 0) and (local_x < thick) and
                   (local_y >= thick/2) and (local_y < digit_h/2 - 1) then
                  seg_on := true;
                end if;

                -- g
                if (segs(0) = '1') and
                   (local_y >= digit_h/2 - thick/2) and (local_y < digit_h/2 + thick/2) and
                   (local_x >= thick/2) and (local_x < digit_w - thick/2) then
                  seg_on := true;
                end if;
              end if;
            end if;
          end if;

          if on_digit and seg_on then
            Red   <= text_r;
            Green <= text_g;
            Blue  <= text_b;
          end if;
        end if;
      end if;
    end loop;
  end process;
end behavior;