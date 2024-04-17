----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/06/2022 08:11:19 PM
-- Design Name: 
-- Module Name: baud_gen - Behavioral
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


library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity baud_gen is
port(
    clk : in std_logic ;
    reset : in std_logic ;
    dvsr : in std_logic_vector (10 downto 0);
    tick : out std_logic
);
end baud_gen ;

architecture behavioral of baud_gen is
constant N : integer := 11;
signal r_reg : unsigned (N - 1 downto 0);
signal r_next : unsigned (N - 1 downto 0);

begin

-- r e g i s t e r
process( clk , reset )
begin
if ( reset = '1') then
    r_reg <= (others => '0');
elsif ( clk'event and clk = '1') then
    r_reg <= r_next ;
end if ;
end process;
-- nex t-s t a t e l o g i c
r_next <= (others => '0') when r_reg = unsigned(dvsr) else r_reg + 1;
-- o u t p u t l o g i c
tick <= '1' when r_reg =1 else '0'; -- no t use 0 bec au se o f r e s e t

end Behavioral;