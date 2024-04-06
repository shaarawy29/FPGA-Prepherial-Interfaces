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

entity test_text is
    port (
        nrst, clk : in std_logic;
        r, g, b : out std_logic_vector (3 downto 0);
        hsync , vsync : out std_logic);
end entity;

architecture behavioural of test_text is

    COMPONENT font_ROM
    PORT (
        clka : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
    END COMPONENT;

    component VGA_controller is
        Port ( clk, nrst : in std_logic;
               pos_x, pos_y : out std_logic_vector (9 downto 0);
               video_on : out std_logic;
               hsync , vsync : out std_logic);
    end component;

    signal pos_x, pos_y : std_logic_vector (9 downto 0);
    signal video_on : std_logic;
    signal font_word : std_logic_vector (7 downto 0);
    signal rom_addr : std_logic_vector (7 downto 0);
    signal font_bit : std_logic;

begin

    rom_addr <= "0000" & pos_y(3 downto 0);        
    font_bit <= font_word(7) when pos_x(2 downto 0) = "000" else
                font_word(6) when pos_x(2 downto 0) = "001" else
                font_word(5) when pos_x(2 downto 0) = "010" else
                font_word(4) when pos_x(2 downto 0) = "011" else
                font_word(3) when pos_x(2 downto 0) = "100" else
                font_word(2) when pos_x(2 downto 0) = "101" else
                font_word(1) when pos_x(2 downto 0) = "110" else
                font_word(0) when pos_x(2 downto 0) = "111" else
                '0';
    r <= (others => font_bit);
    g <= (others => font_bit);
    b <= (others => font_bit);   

    VGA_controller_unit : VGA_controller port map ( clk => clk,
        nrst => nrst,
        pos_x => pos_x,
        pos_y => pos_y,
        video_on => video_on,
        hsync => hsync,
        vsync => vsync);
    
    rom : font_ROM PORT MAP (
        clka => clk,
        ena => '1',
        addra => rom_addr,
        douta => font_word);

end architecture;