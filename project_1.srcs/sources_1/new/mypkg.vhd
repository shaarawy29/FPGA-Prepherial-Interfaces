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

    type char_array is array (natural range<>) of std_logic_vector(5 downto 0);
--     type current_score_array is array (natural range<>) of std_logic_vector(5 downto 0);

    ------------------------- constat definition -----------------------------------
    constant HD: integer := 640; --horizontal display area
    constant VD: integer := 480; --vertical display area
    constant image_w: integer := 200; -- image width
    constant image_h: integer := 480; -- image height
    constant car_w : integer := 40;
    constant car_h : integer := 40;
    constant carp2_w : integer := 40;
    constant carp2_h : integer := 40;
    
    constant ps2_inc : integer := 5;
    
    constant max_score : integer := 200;

    constant high_score_index : char_array (0 to 10) := (
        "010001", -- H index 17
        "010010", -- I index 18
        "010000", -- G index 16
        "010001", -- H index 17
        "100100", -- space index 36
        "011100", -- S index 28
        "001100", -- C index 12
        "011000", -- O index 24
        "011011", -- R index 27
        "001110", -- E index 14
        "100100"  -- space index 36
    );

    constant score_index : char_array (0 to 5) := (
        "011100", -- S index 28
        "001100", -- C index 12
        "011000", -- O index 24
        "011011", -- R index 27
        "001110", -- E index 14
        "100100"  -- space index 36
    );
    
    constant player_one_end : char_array (0 to 14) := (
       "011001", -- P index 25
       "010101", -- L index 21
       "001010", -- A index 10
       "100010", -- Y index 34
       "001110", -- E index 14
       "011011", -- R index 27
       "100100", -- space index 36
       "000001", -- 1 index 1
       "100100", -- space index 36
       "011100", -- s index 28
       "001100", -- c index 12
       "011000", -- O index 24    
       "011011", -- R index 27    
       "001110", -- E index 14   
       "100100"  -- space index 36
    );           
    
    constant player_two_end : char_array (0 to 14) := (
       "011001", -- P index 25
       "010101", -- L index 21
       "001010", -- A index 10
       "100010", -- Y index 34
       "001110", -- E index 14
       "011011", -- R index 27
       "100100", -- space index 36
       "000010", -- 2 index 2
       "100100", -- space index 36
       "011100", -- s index 28
       "001100", -- c index 12
       "011000", -- O index 24    
       "011011", -- R index 27    
       "001110", -- E index 14   
       "100100"  -- space index 36
    );


end package mypkg;