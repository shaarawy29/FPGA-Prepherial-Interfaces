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



entity score_display is
    port (
        clk, nrst  : in std_logic;
        pos_x, pos_y : in std_logic_vector (9 downto 0);
        high_score, score : in std_logic_vector (11 downto 0);
        score_pixel : out std_logic_vector (11 downto 0));
end score_display;


architecture behavioural of score_display is

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

    COMPONENT font
    PORT (
        clka : IN STD_LOGIC;
        addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
    END COMPONENT;


    signal digit_rom_addr : std_logic_vector (7 downto 0);
    signal char_rom_addr : std_logic_vector (8 downto 0);
    signal font_rom_addr : std_logic_vector (9 downto  0);
    signal digits_font_rom_word, char_font_rom_word : std_logic_vector (7 downto 0);
    signal char_font_rom : std_logic;
    signal font_word : std_logic_vector(7 downto 0);
    signal font_bit : std_logic;
    signal high_score_digits, score_digits : std_logic_vector (15 downto 0);
    signal bcd_busy1, bcd_busy2 : std_logic;

begin

    -- process to get the font address either from the char or digits memory
    process (pos_x, pos_y)
    begin
        if ((unsigned(pos_x(9 downto 3)) >= 10) and (unsigned(pos_x(9 downto 3)) <= 24) and (unsigned(pos_y) >= 0) and (unsigned(pos_y) <= 15)) then
            if((unsigned(pos_x(9 downto 3)) >= 10) and (unsigned(pos_x(9 downto 3)) <= 20)) then
                font_rom_addr <= high_score_index(to_integer(unsigned(pos_x(9 downto 3)) - 10)) & pos_y(3 downto 0);
            else
                case unsigned(pos_x(9 downto 3)) is
                    when "0010101" => font_rom_addr <= "00" & high_score_digits(15 downto 12) & pos_y(3 downto 0);
                    when "0010110" => font_rom_addr <= "00" & high_score_digits(11 downto 8) & pos_y(3 downto 0);
                    when "0010111" => font_rom_addr <= "00" & high_score_digits(7 downto 4) & pos_y(3 downto 0);
                    when "0011000" => font_rom_addr <= "00" & high_score_digits(3 downto 0) & pos_y(3 downto 0);
                    when others => font_rom_addr <= ((others => '0'));
                end case;
            end if;
        elsif ((unsigned(pos_x(9 downto 3)) >= 15) and (unsigned(pos_x(9 downto 3)) <= 24) and (unsigned(pos_y) >= 16) and (unsigned(pos_y) <= 31)) then
            if((unsigned(pos_x(9 downto 3)) >= 15) and (unsigned(pos_x(9 downto 3)) <= 20)) then
                font_rom_addr <= score_index(to_integer(unsigned(pos_x(9 downto 3)) - 15)) & pos_y(3 downto 0);
            else
                case unsigned(pos_x(9 downto 3)) is
                    when "0010101" => font_rom_addr <= "00" & score_digits(15 downto 12) & pos_y(3 downto 0);
                    when "0010110" => font_rom_addr <= "00" & score_digits(11 downto 8) & pos_y(3 downto 0);
                    when "0010111" => font_rom_addr <= "00" & score_digits(7 downto 4) & pos_y(3 downto 0);
                    when "0011000" => font_rom_addr <= "00" & score_digits(3 downto 0) & pos_y(3 downto 0);
                    when others => font_rom_addr <= ((others => '0'));
                end case;
            end if;
        else
            font_rom_addr <= "100100" & pos_y(3 downto 0);
        end if;
    end process;

    -- mapping the font data to the score pixel
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

    rom : font PORT MAP (
                clka => clk,
                addra => font_rom_addr,
                douta => font_word);

    bcd1 : binary_to_bcd 
            generic map(
                bits => 12,
                digits => 4)
            port map(
                clk => clk,                           
                reset_n => nrst,                      
                ena => '1',                        
                binary => std_logic_vector(high_score),
                busy => bcd_busy1,                     
                bcd => high_score_digits);

    bcd2 : binary_to_bcd 
            generic map(
                bits => 12,
                digits => 4)
            port map(
                clk => clk,                           
                reset_n => nrst,                      
                ena => '1',                        
                binary => std_logic_vector(score),
                busy => bcd_busy2,                     
                bcd => score_digits);

end behavioural;