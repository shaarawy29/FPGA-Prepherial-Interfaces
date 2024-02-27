----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/27/2024 08:33:11 AM
-- Design Name: 
-- Module Name: VGA_controller - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity VGA_controller is
    Port ( clk, nrst : in std_logic;
           pos_x, pos_y : out std_logic_vector (9 downto 0);
           video_on : out std_logic;
           hsync , vsync : out std_logic);
end VGA_controller;

architecture Behavioral of VGA_controller is

     -- VGA 640-by -480 sync parameters
    constant HD: integer := 640; --horizontal display area
    constant HF: integer:= 16 ; --h. front porch
    constant HB: integer:= 48 ; --h. back porch
    constant HR: integer:= 96 ; --h. retrace
    constant VD: integer := 480; --vertical display area
    constant VF: integer:= 10; -- v. front porch
    constant VB: integer := 33; -- v. back porch
    constant VR: integer := 2; -- v. retrace
    
    signal clk_divider_count : unsigned(1 downto 0) := "00";
    signal clk_25MHz : std_logic := '0';
    
     -- sync counters
    signal v_count : unsigned(9 downto 0) ;
    signal h_count : unsigned (9 downto 0) ;
    -- status signal
    signal h_end , v_end : std_logic;
    
    
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
    process (clk_25MHz, nrst) begin
        if(nrst = '0') then 
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
    process (clk_25MHz, nrst) begin
        if (nrst = '0') then
            v_count <= (others => '0');
        elsif (rising_edge(clk_25MHz)) and (h_end = '1') then
            if (v_end = '1') then
                v_count <= (others=>'0');
            else
                v_count <= v_count + 1;
            end if;
        end if; 
    end process;
    
    process(clk_25MHz, nrst) begin
        if (nrst = '0') then 
            video_on <= '0';
        elsif (rising_edge(clk_25MHz)) then
            if (h_count <= HD-1 and v_count <= VD-1) then
                video_on <= '1';
            else
                video_on <= '0';
            end if;
        end if;
    end process;
    
    hsync <=
        '1' when (h_count >= (HD + HF)) --656
            and (h_count <= (HD + HF + HR - 1)) else --751 
        '0';
    vsync <=
        '1' when ( v_count >= (VD + VF)) --490
            and (v_count <= (VD + VF + VR - 1)) else --491
        '0';
        
    pos_x <= std_logic_vector(h_count);
    pos_y <= std_logic_vector(v_count);

end Behavioral;
