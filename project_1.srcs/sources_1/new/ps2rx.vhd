----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/05/2022 12:02:07 PM
-- Design Name: 
-- Module Name: keyboard - Behavioral
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


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity ps2rx is
    port (
        clk, rst : in std_logic;
        ps2d, ps2c : in std_logic;
        rx_en : in std_logic;
        rx_done_tick : out std_logic;
        shift_en : out std_logic;
        dout : out std_logic_vector(7 downto 0)
    );
end ps2rx;
 
architecture arch of ps2rx is
    type statetype is (idle, dps, load);
    signal state_reg, state_next : statetype;
    -- filter
    signal filter_reg, filter_next : std_logic_vector(7 downto 0);
    signal f_ps2c_reg, f_ps2c_next : std_logic;
 
    signal b_reg, b_next : std_logic_vector(10 downto 0);
    signal n_reg, n_next : unsigned(3 downto 0);
    signal shift_reg, shift_next : std_logic := '0';
    signal last_reg, last_next : std_logic := '0';
     
    signal fall_edge : std_logic;
     
begin
 
-- filter
process (clk, rst)
begin
  if (rst = '1') then
    filter_reg <= (others => '0');
    f_ps2c_reg <= '0';
  elsif (clk'event and clk='1') then
    filter_reg <= filter_next;
    f_ps2c_reg <= f_ps2c_next;
  end if;
end process;
 
 
filter_next <= ps2c & filter_reg(7 downto 1);
f_ps2c_next <= '1' when filter_reg = "11111111" else
               '0' when filter_reg = "00000000" else
               f_ps2c_reg;
 
fall_edge <= f_ps2c_reg and (not f_ps2c_next);
 
-- registers
process (clk, rst)
begin
    if (rst = '1') then
        state_reg <= idle;
        n_reg <= (others => '0');
        b_reg <= (others => '0');
    elsif (clk'event and clk='1') then
        state_reg <= state_next;
        n_reg <= n_next;
        b_reg <= b_next;
        shift_reg <= shift_next;
        last_reg <= last_next;
    end if;
end process;
 
-- next-state logic
process(state_reg, n_reg, b_reg, fall_edge, rx_en, ps2d, shift_reg, last_reg)
begin
    rx_done_tick <= '0';
    state_next <= state_reg;
    n_next <= n_reg;
    b_next <= b_reg;
    shift_next <= shift_reg;
    last_next <= last_reg;
   
  case state_reg is
    when idle =>
      if (fall_edge = '1' and rx_en='1') then
        --shift in start bit
        b_next <= ps2d & b_reg(10 downto 1);
        n_next <= "1001"; -- set count to 8 again
        state_next <= dps;
      end if;
    when dps =>
      if (fall_edge = '1' ) then
        b_next <= ps2d & b_reg(10 downto 1);
        if (n_reg = 0) then
          state_next <= load;
        else
          n_next <= n_reg - 1;
        end if;
      end if;
    when load =>
        -- here we handle if signal f0 and following signal are
        -- asserted - we don't want to transmit them to dout.
      -- one more state to complete last shift
        state_next <= idle;
        rx_done_tick <= '1';
        if (b_reg(8 downto 1) = x"12" or b_reg(8 downto 1) = x"59") then
            shift_next <= not shift_reg;
            if (last_reg = '1') then
                rx_done_tick <= '1';
                last_next <= '0';
            end if;
        elsif (b_reg(8 downto 1) = "11110000") then
            last_next <= '1';
            rx_done_tick <= '0';
        elsif (last_reg = '1') then
            last_next <= '0';   
            rx_done_tick <= '0';
        end if;
  end case;
end process;
 
shift_en <= shift_reg;
dout <= b_reg(8 downto 1);
 
end arch;