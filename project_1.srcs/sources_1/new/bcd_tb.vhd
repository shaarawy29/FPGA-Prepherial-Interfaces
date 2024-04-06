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


entity bcd_tb is
   -- port ();
end entity;

architecture rtl of bcd_tb is
    -- clk score signals 
    signal clk : std_logic := '0';
    signal clk_score_count : unsigned (26 downto 0) := ((others => '0'));
    signal clk_score : unsigned(11 downto 0) := (others => '0') ;
    signal rom_addr : std_logic_vector (7 downto 0);
    signal rom_addr_tmp : std_logic_vector (11 downto 0);
    signal font_word : std_logic_vector (7 downto 0);
    signal font_bit : std_logic;
    signal bcd_busy : std_logic;
    signal digits : std_logic_vector (15 downto 0);
    signal score_pixel : std_logic_vector (11 downto 0);
    signal bcd_en : std_logic;
    signal nrst : std_logic := '0';

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

begin

    process 
    begin
        wait for 5 ns;
        clk <= not(clk);
    end process;

    process
    begin
        nrst <= '0'; wait for 23 ns; nrst <= '1';
        bcd_en <= '1';
        clk_score <= "000000000111";
        wait for 5ns;
        clk_score <= "000000011001";
        wait for 5ns;
        clk_score <= "111010101011";
        wait for 5ns;
        clk_score <= "010101010101";
        wait for 5ns;
        clk_score <= "011100111011";
        wait for 100ns;
        clk_score <= "111100110011";
        wait for 5ns;
        clk_score <= "011010101000";
        wait for 5ns;
        clk_score <= "110111000111";
        wait for 5ns;
        clk_score <= "010111001111";
        wait;
    end process;
    
    bcd : binary_to_bcd 
        generic map(
            bits => 12,
            digits => 4)
        port map(
            clk => clk,                           
            reset_n => nrst,                      
            ena => bcd_en,                        
            binary => std_logic_vector(clk_score),
            busy => bcd_busy,                     
            bcd => digits);

end architecture;