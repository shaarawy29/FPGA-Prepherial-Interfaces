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
           xon, yon : in std_logic;
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
    
    
    signal curr_pixel : std_logic_vector (11 downto 0);
    signal temp_pixel : std_logic_vector (11 downto 0);
    signal index : unsigned (19 downto 0);
    signal video_on : std_logic;
    signal pos_x, pos_y : std_logic_vector (9 downto 0);
    
    -- shift parameters 
    signal shift_x, shift_y : unsigned (9 downto 0);
    
    -- clk division counter
    signal clk_divider_count : unsigned (19 downto 0) := "00000000000000000000";
    signal clk_1MHz : std_logic := '0';


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

    process(clk_1MHz, nrst)begin
        if(nrst = '0') then
            shift_x <= (others => '0');
            shift_y <= (others => '0');
        elsif (clk_1MHz'event and clk_1MHz = '1')then
            if(xon = '1') then
                shift_x <= shift_x + 1;
                if(shift_x = 540) then
                    shift_x <= (others => '0');
                end if;
            end if;
            
            if(yon = '1') then
                shift_y <= shift_y + 1;
                if(shift_y = 380) then
                    shift_y <= (others => '0');
                end if;
            end if;
            
        end if;
    end process;

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
                                  
    index <= (((unsigned(pos_y) - shift_y) * 100) + (unsigned(pos_x)) - shift_x) when ((unsigned(pos_x) >= shift_x and unsigned(pos_x) <= (shift_x + 99)) and (unsigned(pos_y) >= shift_y and unsigned(pos_y) <= (shift_y + 99))) else (others => '0');
    curr_pixel <= temp_pixel when ((unsigned(pos_x) >= shift_x and unsigned(pos_x) <= (shift_x + 99)) and (unsigned(pos_y) >= shift_y and unsigned(pos_y) <= (shift_y + 99))) else (others => '0');

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
