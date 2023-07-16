----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2023/07/03 17:25:43
-- Design Name: 
-- Module Name: EDGE_DETECT - Behv
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity EDGE_DETECT is
    Port (
		clk : in std_logic;
		rst : in std_logic;
		signal_in : in std_logic;
		pos_edge : out std_logic;
		neg_edge : out std_logic
		);
end EDGE_DETECT;

architecture Behv of EDGE_DETECT is
		signal buff : std_logic_vector( 1 downto 0 ) := "00";
begin
		EDGE_DETECT_PROC: process(rst, clk ) is
		begin
			if( rst = '1' ) then
				buff <= "00";
			elsif ( rising_edge( clk ) ) then
				buff(0) <= signal_in;
				buff(1) <= buff(0);
			end if;
		end process EDGE_DETECT_PROC;
		
		pos_edge <= buff(0) and not buff(1);
		neg_edge <= not buff(0) and buff(1);

end Behv;
