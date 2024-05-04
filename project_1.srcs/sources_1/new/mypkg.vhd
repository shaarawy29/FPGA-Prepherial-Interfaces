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


package mypkg is 

    ------------------------------ type declaration -------------------------------------
    type coordinates is record 
        x_start : std_logic_vector (9 downto 0);
        x_end : std_logic_vector (9 downto 0);
        y_start : std_logic_vector(9 downto 0);
        y_end : std_logic_vector(9 downto 0);
    end record coordinates;

    type high_score_array is array (natural range<>) of std_logic_vector(4 downto 0);
    type current_score_array is array (natural range<>) of std_logic_vector(4 downto 0);

    ------------------------- constat definition -----------------------------------
    constant HD: integer := 640; --horizontal display area
    constant VD: integer := 480; --vertical display area
    constant image_w: integer := 200; -- image width
    constant image_h: integer := 480; -- image height
    constant car_w : integer := 40;
    constant car_h : integer := 40;
    constant carp2_w : integer := 40;
    constant carp2_h : integer := 40;

    constant high_score_index : high_score_array (0 to 10) := (
        "00111", -- H index 7
        "01000", -- I index 8
        "00110", -- G index 6
        "00111", -- H index 7
        "11010", -- space index 26
        "10010", -- S index 18
        "00010", -- C index 2
        "01110", -- O index 14
        "10001", -- R index 17
        "00100", -- E index 4
        "11010"  -- space index 26
    );

    constant score_index : current_score_array (0 to 5) := (
        "10010", -- S index 18
        "00010", -- C index 2
        "01110", -- O index 14
        "10001", -- R index 17
        "00100", -- E index 4
        "11010"  -- space index 26
    );


end package mypkg;