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


begin

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
                                  
    index <= ((unsigned(pos_y) * 100) + unsigned(pos_x)) when (pos_y <= 99 and pos_x <= 99) else (others => '0');
    curr_pixel <= temp_pixel when (pos_y <= 99 and pos_x <= 99) else (others => '0');

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
