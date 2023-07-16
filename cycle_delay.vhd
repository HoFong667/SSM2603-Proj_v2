----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2023/07/13 15:18:09
-- Design Name: 
-- Module Name: cycle_delay - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cycle_delay is
Port (
    rst_i:      in std_logic;
    clk_i:      in std_logic;
    signal_i:   in std_logic;
    delay_o:    out std_logic
);
end cycle_delay;

architecture Behavioral of cycle_delay is
    type states is ( idle, counting );
    signal c_state: states := idle;

    signal cnt:             unsigned( 15 downto 0 ) := ( others => '1' );       -- 16 bit cycle delay make approx. 12ms delay under 5Mhz clock
    signal i_signal_i:      std_logic;
begin
    state_proc: process( clk_i, rst_i )
    begin
        if rst_i = '1' then
            c_state <= idle;
        elsif rising_edge( clk_i ) then
            if( signal_i = '1' ) then c_state <= counting;
            elsif cnt = 0 then c_state <= idle;
            end if;
        end if;
    end process state_proc;
    
    cnt_proc: process( clk_i, rst_i )
    begin
        if rst_i = '1' then
            cnt <= ( others => '1' );
        elsif rising_edge( clk_i ) then
            case c_state is
                when counting =>
                    cnt <= cnt - "1";
                when others =>
                    cnt <= cnt;
            end case;
        end if;
    end process cnt_proc;
    
    delay_o <= '1' when cnt = 0 else '0';

end Behavioral;
