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

entity game_tb is
    
end entity;

architecture rtl of game_tb is

    component game is
        Port (  clk, nrst: in std_logic;
                up, dn, left, right : in std_logic;
                speed : in std_logic_vector (2 downto 0);
                r, g, b : out std_logic_vector (3 downto 0);
                hsync , vsync : out std_logic);
    end component;
    
    signal clk, nrst, up, dn, left, right : std_logic := '0';
    signal speed : std_logic_vector (2 downto 0) := "000";
    signal r, g, b : std_logic_vector (3 downto 0);
    signal hsync, vsync : std_logic;

begin

    DUT : game Port map (clk => clk,
                        nrst => nrst,
                        up => up,
                        dn => dn,
                        left => left,
                        right => right,
                        speed => speed,
                        r => r,
                        g => g,
                        b => b,
                        hsync => hsync,
                        vsync => vsync
                        );    

    process
    begin
        wait for 5ns; clk <= not(clk);
    end process;

    process
    begin
        nrst <= '0'; wait for 23ns; nrst <= '1';
        right <= '1'; wait for 200ns; wait;
    end process;
    

end architecture;