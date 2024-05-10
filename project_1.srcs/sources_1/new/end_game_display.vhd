----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/10/2024 09:28:43 PM
-- Design Name: 
-- Module Name: end_game_display - Behavioral
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
use work.mypkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity end_game_display is
    port (
        clk, nrst  : in std_logic;
        pos_x, pos_y : in std_logic_vector (9 downto 0);
        score1, score2 : in std_logic_vector (11 downto 0);
        end_pixel : out std_logic_vector (11 downto 0));
end end_game_display;

architecture Behavioral of end_game_display is

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
    
    signal score1_digits, score2_digits : std_logic_vector(15 downto 0);
    signal font_word : std_logic_vector(7 downto 0);
    signal rom_addr : std_logic_vector(9 downto 0);
    signal font_bit : std_logic;
    signal bcd1_busy, bcd2_busy : std_logic;

begin

    -- process to get the font address either from the char or digits memory
    process (pos_x, pos_y)
    begin
        if ((unsigned(pos_x) >= 104) and (unsigned(pos_x) <= 255) and (unsigned(pos_y) >= 0) and (unsigned(pos_y) >= 208) and (unsigned(pos_y) <= 223)) then
            if((unsigned(pos_x) >= 104) and (unsigned(pos_x) < 224)) then
                rom_addr <= player_one_end(to_integer(unsigned(pos_x(9 downto 3)) - 13)) & pos_y(3 downto 0);
            else
                case unsigned(pos_x(9 downto 3)) is
                    when "0011100" => rom_addr <= "00" & score1_digits(15 downto 12) & pos_y(3 downto 0);
                    when "0011101" => rom_addr <= "00" & score1_digits(11 downto 8) & pos_y(3 downto 0);
                    when "0011110" => rom_addr <= "00" & score1_digits(7 downto 4) & pos_y(3 downto 0);
                    when "0011111" => rom_addr <= "00" & score1_digits(3 downto 0) & pos_y(3 downto 0);
                    when others => rom_addr <= "100100" & pos_y(3 downto 0);
                end case;
            end if;
        elsif ((unsigned(pos_x) >= 104) and (unsigned(pos_x) <= 255) and (unsigned(pos_y) >= 16) and (unsigned(pos_y) >= 224) and (unsigned(pos_y) <= 239)) then
            if((unsigned(pos_x) >= 104) and (unsigned(pos_x) < 224)) then
                rom_addr <= player_two_end(to_integer(unsigned(pos_x(9 downto 3)) - 13)) & pos_y(3 downto 0);
            else
                case unsigned(pos_x(9 downto 3)) is
                    when "0011100" => rom_addr <= "00" & score2_digits(15 downto 12) & pos_y(3 downto 0);
                    when "0011101" => rom_addr <= "00" & score2_digits(11 downto 8) & pos_y(3 downto 0);
                    when "0011110" => rom_addr <= "00" & score2_digits(7 downto 4) & pos_y(3 downto 0);
                    when "0011111" => rom_addr <= "00" & score2_digits(3 downto 0) & pos_y(3 downto 0);
                    when others => rom_addr <= "100100" & pos_y(3 downto 0);
                end case;
            end if;
        else
            rom_addr <= "100100" & pos_y(3 downto 0);
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

    end_pixel <= (others => font_bit); 


    rom : font PORT MAP (
                clka => clk,
                addra => rom_addr,
                douta => font_word);

    bcd1 : binary_to_bcd 
            generic map(
                bits => 12,
                digits => 4)
            port map(
                clk => clk,                           
                reset_n => nrst,                      
                ena => '1',                        
                binary => score1,
                busy => bcd1_busy,                     
                bcd => score1_digits);

    bcd2 : binary_to_bcd 
            generic map(
                bits => 12,
                digits => 4)
            port map(
                clk => clk,                           
                reset_n => nrst,                      
                ena => '1',                        
                binary => score2,
                busy => bcd2_busy,                     
                bcd => score2_digits);


end Behavioral;
