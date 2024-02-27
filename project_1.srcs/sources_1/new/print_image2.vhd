----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/22/2024 03:06:50 PM
-- Design Name: 
-- Module Name: print_image2 - Behavioral
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

entity print_image2 is
  Port ( clk, reset: in std_logic;
         r, g, b : out std_logic_vector (3 downto 0);
         hsync , vsync : out std_logic);
end print_image2;

architecture Behavioral of print_image2 is

  component mem9000 IS
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
  );
END component;

    -- VGA 640-by -480 sync parameters
    constant HD: integer := 640; --horizontal display area
    constant HF: integer:= 16 ; --h. front porch
    constant HB: integer:= 48 ; --h. back porch
    constant HR: integer:= 96 ; --h. retrace
    constant VD: integer := 480; --vertical display area
    constant VF: integer:= 10; -- v. front porch
    constant VB: integer := 33; -- v. back porch
    constant VR: integer := 2; -- v. retrace
    
    signal clk_divider_count: unsigned(1 downto 0) := "00";
    signal clk_25MHz : std_logic := '0';
    
     -- sync counters
    signal v_count : unsigned(9 downto 0) ;
    signal h_count : unsigned (9 downto 0) ;
    signal index : unsigned (19 downto 0);
    signal video_on : std_logic;
    -- status signal
    signal h_end , v_end : std_logic;
    
    type myarray is array (0 to 312799) of std_logic_vector(11 downto 0);
    signal image : myarray;
    signal curr_pixel : std_logic_vector (11 downto 0);
    signal temp_pixel : std_logic_vector (11 downto 0);
    
begin

    -- clock division code
    process(clk)begin
        if (clk'event and clk = '1') then
            if(clk_divider_count = "01") then
                clk_25MHz <= not(clk_25MHz);
                clk_divider_count <= "00";
            else
                clk_divider_count <= clk_divider_count + 1;
            end if;
        end if;
    end process;
    
    
    -- status
    h_end <= -- end of horizontal counter
    '1' when h_count = (HD + HF + HB + HR - 1) else --799
    '0';
    v_end <= -- end of vertical counter
    '1' when v_count = (VD + VF + VB + VR - 1) else --524 
    '0';
    
    -- mod-800 horizontal sync counter
    process (clk_25MHz, reset) begin
        if(reset = '1') then 
            h_count <= (others => '0');
        elsif rising_edge(clk_25MHz) then -- 25 MHz tick
            if h_end = '1' then
                h_count <= (others=>'0');
            else
                h_count <= h_count + 1;
            end if;
        end if;
    end process;
    
    -- mod-525 vertical sync counter
    process (clk_25MHz, reset) begin
        if (reset = '1') then
            v_count <= (others => '0');
        elsif (rising_edge(clk_25MHz)) and (h_end = '1') then
            if (v_end = '1') then
                v_count <= (others=>'0');
            else
                v_count <= v_count + 1;
            end if;
        end if; 
    end process;
    
    process(clk_25MHz, reset) begin
        if (reset = '1') then 
            video_on <= '0';
        elsif (rising_edge(clk_25MHz)) then
            if (h_count <= HD-1 and v_count <= VD-1) then
                video_on <= '1';
            else
                video_on <= '0';
            end if;
        end if;
    end process;
    
     -- assigning the rgb values
--    r <= (others => curr_pixel) when (video_on = '1') else (others => '0');
--    g <= (others => curr_pixel) when (video_on = '1') else (others => '0');
--    b <= (others => curr_pixel) when (video_on = '1') else (others => '0');
    
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
    
    -- horizontal and vertical sync, buffered to avoid glitch
    hsync <=
        '1' when (h_count >= (HD + HF)) --656
            and (h_count <= (HD + HF + HR - 1)) else --751 
        '0';
    vsync <=
        '1' when ( v_count >= (VD + VF)) --490
            and (v_count <= (VD + VF + VR - 1)) else --491
        '0';
        
     index <= ((v_count * 300) + (h_count)) when (v_count <= 299 and h_count <= 299) else (others => '0');
     curr_pixel <= temp_pixel when (v_count <= 299 and h_count <= 299) else (others => '0');

    -- array hard coded 
    mem : mem9000 port map (clka => clk_25MHz, 
                                  ena => video_on,
                                  wea => "0",
                                  addra => std_logic_Vector(index(16 downto 0)),
                                  dina => (others => '0'),
                                  douta => temp_pixel);
end Behavioral;