----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/07/2024 08:12:51 AM
-- Design Name: 
-- Module Name: game - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use ieee.numeric_std.all ; 
use ieee.std_logic_arith;
use ieee.std_logic_unsigned.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
use work.mypkg.all;

entity game is
    Port (  clk, nrst: in std_logic;
            up, dn, left, right : in std_logic;
            speed : in std_logic_vector (2 downto 0);
            r, g, b : out std_logic_vector (3 downto 0);
            hsync , vsync : out std_logic);
end game;

architecture Behavioral of game is

    ----------------------------- component declaration ----------------------------------------
    component VGA_controller is
        Port ( clk, nrst : in std_logic;
               pos_x, pos_y : out std_logic_vector (9 downto 0);
               video_on : out std_logic;
               hsync , vsync : out std_logic);
    end component;
    
    component frame_mem IS
      PORT (
        clka : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        douta : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
      );
    END component;

    COMPONENT car_mem
        PORT (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
            douta : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT ob1
        PORT (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
            douta : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT font_ROM
    PORT (
        clka : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
    END COMPONENT;

    component binary_to_bcd IS
        GENERIC(
            bits   : INTEGER := 10;  --size of the binary input numbers in bits
            digits : INTEGER := 3);  --number of BCD digits to convert to
        PORT(
            clk     : IN    STD_LOGIC;                             --system clock
            reset_n : IN    STD_LOGIC;                             --active low asynchronus reset
            ena     : IN    STD_LOGIC;                             --latches in new binary number and starts conversion
            binary  : IN    STD_LOGIC_VECTOR(bits-1 DOWNTO 0);     --binary number to convert
            busy    : OUT  STD_LOGIC;                              --indicates conversion in progress
            bcd     : OUT  STD_LOGIC_VECTOR(digits*4-1 DOWNTO 0)); --resulting BCD number
    END component;

    component clash_detection is
        port (
            nrst   : in std_logic;
            clk : in std_logic;
            master, slave : in coordinates;
            pos_x, pos_y : in std_logic_vector(9 downto 0);
            front_clash, back_clash, right_clash, left_clash : out std_logic);
    end component;

    ----------------------------- signal definition ----------------------------------------
    signal curr_pixel : std_logic_vector (11 downto 0);
    signal temp_pixel : std_logic_vector (11 downto 0);
    signal index : unsigned (19 downto 0);
    signal video_on : std_logic;
    signal pos_x, pos_y : std_logic_vector (9 downto 0);

    signal clk_1mhz : std_logic;
    signal speed_condition : std_logic_vector (19 downto 0);
    
    -- shift parameters 
    signal shift_x, shift_y : unsigned (10 downto 0);
    
    -- clk division counter
    signal clk_divider_count : unsigned (19 downto 0) := ((others => '0'));
        
    signal shift_x_abs, shift_y_abs : signed (10 downto 0);
    signal left_right : std_logic_vector (1 downto 0);
    signal up_dn : std_logic_vector (1 downto 0);

    -- frame signals 
    signal index_f : unsigned (19 downto 0);
    signal shift_f : unsigned (8 downto 0);
    signal frame_pixel : std_logic_vector(11 downto 0);
    
    -- care signals
    signal car_pos : coordinates := (x_start => std_logic_vector(to_unsigned(250, 10)),
                                     x_end => std_logic_vector(to_unsigned(290, 10)),
                                     y_start => std_logic_vector(to_unsigned(380, 10)),
                                     y_end => std_logic_vector(to_unsigned(420, 10)));
    signal shift_car : unsigned (6 downto 0);
    signal index_car : unsigned (10 downto 0);
    signal car_pixel : std_logic_vector (11 downto 0);

    -- care red signals
    signal ob1_pos : coordinates := (x_start => std_logic_vector(to_unsigned(250, 10)),
                                     x_end => std_logic_vector(to_unsigned(290, 10)),
                                     y_start => std_logic_vector(to_unsigned(100, 10)),
                                     y_end => std_logic_vector(to_unsigned(140, 10)));
    signal shift_ob1 : unsigned (6 downto 0);
    signal index_ob1 : unsigned (10 downto 0);
    signal ob1_pixel : std_logic_vector (11 downto 0);

    -- clash signals 
    signal front_clash : std_logic;
    signal back_clash : std_logic;
    signal left_clash : std_logic;
    signal right_clash : std_logic;

    -- clk score signals 
    signal clk_score_count : unsigned (26 downto 0) := ((others => '0'));
    signal clk_score : unsigned(11 downto 0) := (others => '0') ;
    signal rom_addr : std_logic_vector (7 downto 0);
    signal rom_addr_tmp : std_logic_vector (7 downto 0);
    signal font_word : std_logic_vector (7 downto 0);
    signal font_bit : std_logic;
    signal bcd_busy : std_logic;
    signal digits : std_logic_vector (15 downto 0);
    signal score_pixel : std_logic_vector (11 downto 0);
    signal bcd_en : std_logic;
    signal bcd1, bcd2, bcd3, bcd4 : std_logic_vector(3 downto 0);
    -- signal add_tmp : std_logic_vector (11 downto 0);
    signal add_tmp_unsigned : unsigned (7 downto 0);

begin

    left_right <= left & right;
    up_dn <= up & dn;
    speed_condition <= not(speed) & '1' & X"FFFF";

    -- score code (clk generation of 1Hz and counting)
    process(clk)begin
        if (rising_edge(clk) and front_clash = '0') then
            if(clk_score_count = "111111111111111111111111111") then
                clk_score <= clk_score + 1;
                clk_score_count <= (others => '0') ;
            else
                clk_score_count <= clk_score_count + 1;
            end if;
        end if;
    end process;

    -- score fetching the correct address from the memory
    bcd1 <= digits (3 downto 0);
    bcd2 <= digits (7 downto 4);
    bcd3 <= digits (11 downto 8);
    bcd4 <= digits (15 downto 12);
    process (pos_x, pos_y)
        variable add_tmp : std_logic_vector (11 downto 0) := "000000000000";
    begin
        if(unsigned(pos_x) >= 183 and unsigned(pos_x) <= 190) then
            add_tmp := (bcd4 * "00010000");
            rom_addr_tmp <= add_tmp(7 downto 4) & pos_y(3 downto 0);
        elsif(unsigned(pos_x) >= 191 and unsigned(pos_x) <= 198) then
            add_tmp := (bcd3 * "00010000");
            rom_addr_tmp <= add_tmp(7 downto 4) & pos_y(3 downto 0);
        elsif(unsigned(pos_x) >= 199 and unsigned(pos_x) <= 206) then
            add_tmp := (bcd2 * "00010000");
            rom_addr_tmp <= add_tmp(7 downto 4) & pos_y(3 downto 0);
        elsif(unsigned(pos_x) >= 207 and unsigned(pos_x) <= 214) then
            add_tmp := (bcd1 * "00010000");
            rom_addr_tmp <= add_tmp(7 downto 4) & pos_y(3 downto 0);
        else 
            rom_addr_tmp <= rom_addr_tmp; --"00000000" & pos_y(3 downto 0);
        end if;
    end process;

    rom_addr <= rom_addr_tmp(7 downto 0);
    font_bit <= font_word(7) when pos_x(2 downto 0) = "000" else
        font_word(6) when pos_x(2 downto 0) = "001" else
        font_word(5) when pos_x(2 downto 0) = "010" else
        font_word(4) when pos_x(2 downto 0) = "011" else
        font_word(3) when pos_x(2 downto 0) = "100" else
        font_word(2) when pos_x(2 downto 0) = "101" else
        font_word(1) when pos_x(2 downto 0) = "110" else
        font_word(0) when pos_x(2 downto 0) = "111" else
        '0';

    score_pixel <= (others => font_bit); 

    -----------------------------------------------------------------

    -- clock division code
    process(clk)begin
        if (rising_edge(clk)) then
            if(clk_divider_count = unsigned(speed_condition)) then
                clk_1mhz <= not(clk_1mhz);
                clk_divider_count <= (others => '0') ;
            else
                clk_divider_count <= clk_divider_count + 1;
            end if;
        end if;
    end process;

    process (clk_1mhz, nrst)
    begin
        if(nrst = '0') then
            shift_f <= ((others => '0'));
        elsif rising_edge(clk_1mhz) then
            -- moving the road
            if(front_clash = '0') then
                if(shift_f = VD) then
                    shift_f <= (others => '0');
                else
                    shift_f <= shift_f + 1;
                end if;
            end if;

            -- moving obsticle 
            if(front_clash = '0') then
                if(ob1_pos.y_end = VD - 1) then
                    ob1_pos.y_end <= (others => '0');
                else
                    ob1_pos.y_end <= ob1_pos.y_end + 1;
                end if;
                if(ob1_pos.y_start = VD - 1) then
                    ob1_pos.y_start <= (others => '0');
                else
                    ob1_pos.y_start <= ob1_pos.y_start + 1;
                end if;
            end if;

            -- moving the car
            -- first moving left-rigt
            case left_right is
                when "00" | "11" => 
                    car_pos.x_start <= car_pos.x_start;
                    car_pos.x_end <= car_pos.x_end;
                when "01" => 
                    if(car_pos.x_end >= 420)then
                        car_pos.x_start <= car_pos.x_start;
                        car_pos.x_end <= car_pos.x_end;
                    elsif(right_clash = '0') then
                        car_pos.x_start <= car_pos.x_start + 1;
                        car_pos.x_end <= car_pos.x_end + 1;
                    end if;
                when "10" => 
                    if(car_pos.x_start <= 220)then
                        car_pos.x_start <= car_pos.x_start;
                        car_pos.x_end <= car_pos.x_end;
                    elsif(left_clash = '0') then
                        car_pos.x_start <= car_pos.x_start - 1;
                        car_pos.x_end <= car_pos.x_end - 1;
                    end if;
                when others =>
                        car_pos.x_start <= car_pos.x_start;
                        car_pos.x_end <= car_pos.x_end;
            end case;
            --second moving front-back
            case up_dn is
                when "00" | "11" => 
                    car_pos.y_start <= car_pos.y_start;
                    car_pos.y_end <= car_pos.y_end;
                when "01" => 
                    if(car_pos.y_end >= VD - 50)then
                        car_pos.y_start <= car_pos.y_start;
                        car_pos.y_end <= car_pos.y_end;
                    elsif(back_clash = '0') then
                        car_pos.y_start <= car_pos.y_start + 1;
                        car_pos.y_end <= car_pos.y_end + 1;
                    end if;
                when "10" => 
                    if(car_pos.y_start <= 50)then
                        car_pos.y_start <= car_pos.y_start;
                        car_pos.y_end <= car_pos.y_end;
                    elsif(front_clash = '0') then
                        car_pos.y_start <= car_pos.y_start - 1;
                        car_pos.y_end <= car_pos.y_end - 1;
                    end if;
                when others =>
                        car_pos.y_start <= car_pos.y_start;
                        car_pos.y_end <= car_pos.y_end; 
            end case;
        end if;
    end process;

    -- fetching the frame pixel from the memory
    process (pos_x, pos_y)
    begin
        if(pos_x >= 220 and pos_x <= (image_w + 220)) then
            if((unsigned(pos_y) >= 0 and unsigned(pos_y) < (shift_f))) then
                index_f <= ((unsigned(pos_y)*image_w) + ((unsigned(pos_x)) - 220) + (VD - shift_f)*image_w);
            elsif((unsigned(pos_y) >= shift_f and unsigned(pos_y) <= (VD - 1))) then
                index_f <= RESIZE((((unsigned(pos_y) - shift_f) * image_w) + (unsigned(pos_x)) - 220), 20);
            else
                index_f <= (others => '0');
            end if;
        else
            index_f <= (others => '0');
        end if;
    end process;
    
    -- fetching the car pixel from the memory
    process (pos_x, pos_y)
    begin
        if((pos_x >= car_pos.x_start) and (pos_x <= car_pos.x_end) and (pos_y >= car_pos.y_start) and (pos_y <= car_pos.y_end)) then
            index_car <= RESIZE((unsigned(pos_y) - unsigned(car_pos.y_start))*car_w + (unsigned(pos_x) - unsigned(car_pos.x_start)), 11);
        end if;
    end process;

    -- fetching the obstacle pixel from the memory 
    process (pos_x, pos_y)
    begin
        if(ob1_pos.y_start <= (VD - 40)) then
            if((unsigned(pos_x) >= unsigned(ob1_pos.x_start) and unsigned(pos_x) <= unsigned(ob1_pos.x_end)) and (unsigned(pos_y) >= unsigned(ob1_pos.y_start) and unsigned(pos_y) <= unsigned(ob1_pos.y_end))) then
                index_ob1 <= RESIZE(((unsigned(pos_y) - unsigned(ob1_pos.y_start)) * 40) + (unsigned(pos_x) - unsigned(ob1_pos.x_start)), 11);
            else 
                index_ob1 <= (others => '0');
            end if;
        else
            if((unsigned(pos_x) >= unsigned(ob1_pos.x_start) and unsigned(pos_x) <= unsigned(ob1_pos.x_end)) and (unsigned(pos_y) >= 0 and unsigned(pos_y) <= unsigned(ob1_pos.y_end))) then
                index_ob1 <= RESIZE(((unsigned(pos_y)*40) + ((unsigned(pos_x)) - unsigned(ob1_pos.x_start)) + (VD - unsigned(ob1_pos.y_start))*40), 11);
            elsif((unsigned(pos_x) >= unsigned(ob1_pos.x_start) and unsigned(pos_x) <= unsigned(ob1_pos.x_end)) and (unsigned(pos_y) >= unsigned(ob1_pos.y_start) and unsigned(pos_y) <= (VD - 1))) then
                index_ob1 <= RESIZE((((unsigned(pos_y) - unsigned(ob1_pos.y_start)) * 40) + (unsigned(pos_x)) - unsigned(ob1_pos.x_start)), 11);
            else
                index_ob1 <= (others => '0');
            end if;
        end if;
    end process;

    -- choose which pixel to be printed on the screen
    process (pos_x, pos_y)
    begin
        -- withing the display area
        if(pos_x >= 220 and pos_x <= (image_w + 220)) then
            if((pos_x >= car_pos.x_start) and (pos_x <= car_pos.x_end) and (pos_y >= car_pos.y_start) and (pos_y <= car_pos.y_end)) then
                if(car_pixel = X"000") then
                    curr_pixel <= frame_pixel;
                else
                    curr_pixel <= car_pixel;
                end if;
            elsif(pos_x >= ob1_pos.x_start) and (pos_x <= ob1_pos.x_end) and (pos_y >= ob1_pos.y_start) and (pos_y <= ob1_pos.y_end) then
                if(ob1_pixel = X"000") then
                    curr_pixel <= frame_pixel;
                else
                    curr_pixel <= ob1_pixel;
                end if;
            else
                curr_pixel <= frame_pixel;
            end if;
        elsif (unsigned(pos_x) >= 182 and unsigned(pos_x) <=215 and unsigned(pos_y) <= 15) then
            curr_pixel <= score_pixel;
        -- outside the display area
        else
            curr_pixel <= ((others => '0'));
        end if;
    end process;
    
    ----------------------- module instantiation ----------------------------------------------
    VGA_controller_unit : VGA_controller port map ( clk => clk,
                                                    nrst => nrst,
                                                    pos_x => pos_x,
                                                    pos_y => pos_y,
                                                    video_on => video_on,
                                                    hsync => hsync,
                                                    vsync => vsync);
                                                        

    frame : frame_mem port map (
                                clka => clk, 
                                ena => video_on,
                                wea => "0",
                                addra => std_logic_Vector(index_f(16 downto 0)),
                                dina => (others => '0'),
                                douta => frame_pixel);


    car : car_mem PORT MAP (
                            clka => clk,
                            ena => video_on,
                            wea => "0",
                            addra => std_logic_vector(index_car),
                            dina => (others => '0'),
                            douta => car_pixel);

    car_red : ob1 PORT MAP (
                            clka => clk,
                            ena => video_on,
                            wea => "0",
                            addra => std_logic_vector(index_ob1),
                            dina => (others => '0'),
                            douta => ob1_pixel);

    rom : font_ROM PORT MAP (
                            clka => clk,
                            ena => '1',
                            addra => rom_addr,
                            douta => font_word);

    bcd : binary_to_bcd 
                        generic map(
                            bits => 12,
                            digits => 4)
                        port map(
                            clk => clk,                           
                            reset_n => nrst,                      
                            ena => '1',                        
                            binary => std_logic_vector(clk_score),
                            busy => bcd_busy,                     
                            bcd => digits);

    clash_detection_unit : clash_detection port map (
                            nrst => nrst,
                            clk => clk,
                            master => car_pos,
                            slave => ob1_pos,
                            pos_x => pos_x,
                            pos_y => pos_y,
                            front_clash => front_clash,
                            back_clash => back_clash,
                            right_clash => right_clash,
                            left_clash => left_clash);

    -------------------------------------- continous assignment ---------------------------------------
                                  
    -- red assignment
    r(3) <= curr_pixel(11) when (video_on = '1') else '0';
    r(2) <= curr_pixel(10) when (video_on = '1') else '0';
    r(1) <= curr_pixel(9) when (video_on = '1') else '0';
    r(0) <= curr_pixel(8) when (video_on = '1') else '0';
    -- green assign
    g(3) <= curr_pixel(7) when (video_on = '1') else '0';
    g(2) <= curr_pixel(6) when (video_on = '1') else '0';
    g(1) <= curr_pixel(5) when (video_on = '1') else '0';
    g(0) <= curr_pixel(4) when (video_on = '1') else '0';
    -- blue 
    b(3) <= curr_pixel(3) when (video_on = '1') else '0';
    b(2) <= curr_pixel(2) when (video_on = '1') else '0';
    b(1) <= curr_pixel(1) when (video_on = '1') else '0';
    b(0) <= curr_pixel(0) when (video_on = '1') else '0';

end Behavioral;

