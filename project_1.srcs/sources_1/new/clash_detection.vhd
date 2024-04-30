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

entity clash_detection is
    port (
        nrst   : in std_logic;
        clk : in std_logic;
        master, slave : in coordinates;
        pos_x, pos_y : in std_logic_vector(9 downto 0);
        front_clash, back_clash, right_clash, left_clash : out std_logic);
end clash_detection;

architecture behavioural of clash_detection is

begin

    -- clash detection
    process (pos_x, pos_y, nrst)
    begin
        if(nrst = '0') then
            front_clash <= '1';
            back_clash <= '1';
            left_clash <= '1';
            right_clash <= '1';
        else
            -- front clash 
            if(((master.x_start >= slave.x_start and master.x_start <= slave.x_end) and (master.y_start = slave.y_end)) or
                ((master.x_end >= slave.x_start and master.x_end <= slave.x_end) and (master.y_start = slave.y_end))) then
                front_clash <= '1';
            else
                front_clash <= '0';
            end if;

            -- back clash
            if(((master.x_start >= slave.x_start and master.x_start <= slave.x_end) and (master.y_end = slave.y_start)) or
                ((master.x_end >= slave.x_start and master.x_end <= slave.x_end) and (master.y_end = slave.y_start))) then
                back_clash <= '1';
            else
                back_clash <= '0';
            end if;

            -- left side clash
            if (((master.x_start = slave.x_end) and (master.y_start >= slave.y_start and master.y_start <= slave.y_end)) or
                ((master.x_start = slave.x_end) and (master.y_end >= slave.y_start and master.y_end <= slave.y_end))) then
                left_clash <= '1';
            else
                left_clash <= '0';        
            end if;

            -- right side clash
            if((master.x_end = slave.x_start) and ((master.y_start >= slave.y_start) and (master.y_start <= slave.y_end))) or
                ((master.x_end = slave.x_start) and ((master.y_end >= slave.y_start) and (master.y_end <= slave.y_end))) then
                right_clash <= '1';
            else 
                right_clash <= '0';
            end if;
        end if;
    end process;

end architecture;