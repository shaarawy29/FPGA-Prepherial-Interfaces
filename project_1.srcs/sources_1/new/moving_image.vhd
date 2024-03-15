----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/27/2024 08:48:20 AM
-- Design Name: 
-- Module Name: moving_image - Behavioral
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

entity moving_image is
    Port ( clk, nrst: in std_logic;
           up, dn, left, right : in std_logic;
           --speed1, speed2, speed3, speed4 : in std_logic;
           r, g, b : out std_logic_vector (3 downto 0);
           hsync , vsync : out std_logic);
end moving_image;

architecture Behavioral of moving_image is

    component VGA_controller is
        Port ( clk, nrst : in std_logic;
               pos_x, pos_y : out std_logic_vector (9 downto 0);
               video_on : out std_logic;
               hsync , vsync : out std_logic);
    end component;
    
    component mem1000 IS
      PORT (
        clka : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        douta : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
      );
    END component;
    
    constant HD: integer := 640; --horizontal display area
    constant VD: integer := 480; --vertical display area
    constant image_w: integer := 40; -- image width
    constant image_h: integer := 40; -- image height
    
    
    signal curr_pixel : std_logic_vector (11 downto 0);
    signal temp_pixel : std_logic_vector (11 downto 0);
    signal index : unsigned (21 downto 0);
    signal video_on : std_logic;
    signal pos_x, pos_y : std_logic_vector (9 downto 0);
    
    -- shift parameters 
    signal shift_x, shift_y : unsigned (10 downto 0);
    
    -- clk division counter
    signal clk_divider_count : unsigned (19 downto 0) := "00000000000000000000";
    signal clk_1MHz : std_logic := '0';
    
    signal shift_x_abs, shift_y_abs : signed (10 downto 0);
    signal left_right : std_logic_vector (1 downto 0);
    signal up_dn : std_logic_vector (1 downto 0);
    signal speed : std_logic_vector (3 downto 0);


begin

    -- clock division code
    process(clk, nrst)begin
        if (clk'event and clk = '1') then
            if(clk_divider_count = "11111111111111111111") then
                clk_1MHz <= not(clk_1MHz);
                clk_divider_count <= "00000000000000000000";
            else
                clk_divider_count <= clk_divider_count + 1;
            end if;
        end if;
    end process;
    
    left_right <= (left & right);
    up_dn <= (up & dn);
    speed <= "0011";--(speed4 & speed3 & speed2 & speed1);

    process(clk_1MHz, nrst)begin
        if(nrst = '0') then
            shift_x_abs <= (others => '0');
            shift_y_abs <= (others => '0');
        elsif (clk_1MHz'event and clk_1MHz = '1')then
            case left_right is
                when "00" | "11" => 
                    shift_x_abs <= shift_x_abs;
                when "01" => 
                    shift_x_abs <= shift_x_abs + TO_INTEGER(unsigned(speed));
                when "10" => 
                    shift_x_abs <= shift_x_abs - TO_INTEGER(unsigned(speed));
            end case;
            
            if(shift_x_abs >= HD - 1 or shift_x_abs <= -(HD - 1)) then
                    shift_x_abs <= (others => '0');
                end if;
            
            case up_dn is
                when "00" | "11" => 
                    shift_y_abs <= shift_y_abs;
                when "01" => 
                    shift_y_abs <= shift_y_abs + TO_INTEGER(unsigned(speed));
                when "10" => 
                    shift_y_abs <= shift_y_abs - TO_INTEGER(unsigned(speed));
            end case;
            
            if(shift_y_abs >= VD - 1 or shift_y_abs <= -(VD - 1)) then
                    shift_y_abs <= (others => '0');
                end if;
            
        end if;
    end process;
    
    shift_x <= unsigned(shift_x_abs) when shift_x_abs >= 0 else unsigned(HD + shift_x_abs);
    shift_y <= unsigned(shift_y_abs) when shift_y_abs >= 0 else unsigned(VD + shift_y_abs);

    VGA_controller_unit : VGA_controller port map ( clk => clk,
                                                    nrst => nrst,
                                                    pos_x => pos_x,
                                                    pos_y => pos_y,
                                                    video_on => video_on,
                                                    hsync => hsync,
                                                    vsync => vsync);
                                                        

    -- array hard coded 
    mem : mem1000 port map (clka => clk, 
                                  ena => video_on,
                                  wea => "0",
                                  addra => std_logic_Vector(index(13 downto 0)),
                                  dina => (others => '0'),
                                  douta => temp_pixel);
                                  
    process(pos_x, pos_y)begin
        if(shift_x <= (HD - image_w)) then
            if(shift_y <= (VD - image_h)) then
                if((unsigned(pos_x) >= shift_x and unsigned(pos_x) <= (shift_x + image_w)) and (unsigned(pos_y) >= shift_y and unsigned(pos_y) <= (shift_y + image_h))) then
                    index <= (((unsigned(pos_y) - shift_y) * image_w) + (unsigned(pos_x)) - shift_x);
                    curr_pixel <= temp_pixel;
                else 
                    index <= (others => '0');
                    curr_pixel <= (others => '1');
                end if;
            else
                if((unsigned(pos_x) >= shift_x and unsigned(pos_x) <= (shift_x + image_w)) and (unsigned(pos_y) >= 0 and unsigned(pos_y) <= (shift_y - (VD - image_h) - 1))) then
                    index <= ((unsigned(pos_y)*image_w) + ((unsigned(pos_x)) - shift_x) + (VD - shift_y)*image_h);
                    curr_pixel <= temp_pixel;
                elsif((unsigned(pos_x) >= shift_x and unsigned(pos_x) <= (shift_x + image_w)) and (unsigned(pos_y) >= shift_y and unsigned(pos_y) <= (VD - 1))) then
                    index <= (((unsigned(pos_y) - shift_y) * image_w) + (unsigned(pos_x)) - shift_x);
                    curr_pixel <= temp_pixel;
                else
                    index <= (others => '0');
                    curr_pixel <= (others => '1');
                end if;
            end if;
        elsif(shift_x > (HD - image_w)) then
            if(shift_y <= (VD - image_h)) then
                if((unsigned(pos_x) >= 0 and unsigned(pos_x) <= (shift_x - (HD - image_w) - 1)) and (unsigned(pos_y) >= shift_y and unsigned(pos_y) <= (shift_y + image_h))) then
                    index <= (((unsigned(pos_y) - shift_y) * image_w) + (unsigned(pos_x) + (HD - shift_x)));
                    curr_pixel <= temp_pixel;
                elsif((unsigned(pos_x) >= shift_x and unsigned(pos_x) <= (HD - 1)) and (unsigned(pos_y) >= shift_y and unsigned(pos_y) <= (shift_y + image_h)))then
                    index <= (((unsigned(pos_y) - shift_y) * image_w) + (unsigned(pos_x) - shift_x));
                    curr_pixel <= temp_pixel;
                else 
                    index <= (others => '0');
                    curr_pixel <= (others => '1');
                end if;
            else
                if((unsigned(pos_x) >= 0 and unsigned(pos_x) <= (shift_x - (HD - image_w) - 1)) and (unsigned(pos_y) >= 0 and unsigned(pos_y) <= (shift_y - (VD - image_h) - 1))) then
                    index <= ((unsigned(pos_y)*image_w) + ((unsigned(pos_x)) + (HD - shift_x)) + (VD - shift_y)*image_w);
                    curr_pixel <= temp_pixel;
                elsif((unsigned(pos_x) >= shift_x and unsigned(pos_x) <= (HD - 1)) and (unsigned(pos_y) >= 0 and unsigned(pos_y) <= (shift_y - (VD - image_h) - 1)))then
                    index <= ((unsigned(pos_y)*image_h) + ((unsigned(pos_x)) - shift_x) + (VD - shift_y)*image_h);
                    curr_pixel <= temp_pixel;
                elsif((unsigned(pos_x) >= 0 and unsigned(pos_x) <= (shift_x - (HD - image_w) - 1)) and (unsigned(pos_y) >= shift_y and unsigned(pos_y) <= (VD - 1)))then
                    index <= (((unsigned(pos_y) - shift_y) * image_w) + (unsigned(pos_x)) + (HD - shift_x));
                    curr_pixel <= temp_pixel;
                elsif((unsigned(pos_x) >= shift_x and unsigned(pos_x) <= (HD - 1)) and (unsigned(pos_y) >= shift_y and unsigned(pos_y) <= (VD - 1))) then
                    index <= (((unsigned(pos_y) - shift_y) * image_w) + (unsigned(pos_x)) - shift_x);
                    curr_pixel <= temp_pixel;
                else
                    index <= (others => '0');
                    curr_pixel <= (others => '1');
                end if;
            end if;
        end if;
    
    end process;
                                  
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
