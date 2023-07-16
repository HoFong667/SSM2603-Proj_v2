----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2023/07/14 14:13:40
-- Design Name: 
-- Module Name: iic_bit_ctrl_v2 - Behavioral
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

entity iic_bit_ctrl_v2 is
Port (
    clk:        in std_logic;
    rst:        in std_logic;
    
    clk_cnt:    in unsigned( 15 downto 0 ) := x"000F";
    
    -- input signal
    sta:        in std_logic;
    wr:        in std_logic;
    sto:        in std_logic;
    s_ack:        in std_logic;
--    m_ack:        in std_logic;
--    m_inv_ack:        in std_logic;
    din:        in std_logic;
    
    -- output
    ack_out:        out std_logic;
    busy:           out std_logic;
    bit_done:        out std_logic;
    
        -- iic lines --
        scl_i:          in std_logic;
        scl_o:          out std_logic;
        scl_oen:        out std_logic;
        sda_i:          in std_logic;
        sda_o:          out std_logic;
        sda_oen:        out std_logic
    
 );
end iic_bit_ctrl_v2;

architecture Behavioral of iic_bit_ctrl_v2 is

    type states is ( idle,
            start_a, start_b, start_c, start_d, start_e, start_f,
            stop_a, stop_b, stop_c, stop_d, stop_e, 
            wr_a, wr_b, wr_c, wr_d, wr_e, 
            s_ack_a, s_ack_b, s_ack_c, s_ack_d, s_ack_e, s_ack_f,
            rd_a, rd_b, rd_c, rd_d, rd_e
--            m_ack_a, m_ack_b, m_ack_c, m_ack_d,
--            m_inv_ack_a, m_inv_ack_b, m_inv_ack_c, m_inv_ack_d
              );
                    
    signal c_state: states := idle;
    
    signal clk_en:          std_logic := '1';
    signal cnt:             unsigned( 15 downto 0 );
    signal go:              std_logic := '0';
    
    signal ictrl:            std_logic_vector( 3 downto 0 ); -- internal control, 0 = scl_c, 1 = sda_o, 2 = scl_oen, 3 = sda_oen
    signal d_scl_i:         std_logic;
begin

    go <= sta or sto or wr or s_ack;
    busy <= '0' when c_state = idle else '1';

    -- generate clk enable signal
    gen_clk_en_proc: process( clk, rst )
    begin
        if rst = '1' then
            cnt <= clk_cnt;
            clk_en <= '0';
        elsif rising_edge( clk ) then
            if( cnt = 0 or c_state = idle )then
                cnt <= clk_cnt;
                clk_en <= '1';
            elsif go = '1' then
                cnt <= cnt - 1;
                clk_en <= '0';
            end if;
        end if;
    end process gen_clk_en_proc;

    -- generate statemachine
    next_state_decoder_proc: process( clk, rst )
    begin
        if rst = '1' then
            c_state <= idle;
            bit_done <= '0';
            ictrl <= "1111";
        elsif rising_edge( clk ) then
            bit_done <= '0';
            if clk_en = '1' then
                case c_state is
                    when idle =>
                        if sta = '1' then c_state <= start_a;
                        elsif sto = '1' then c_state <= stop_a;
                        elsif wr = '1' then c_state <= wr_a;
                        elsif s_ack = '1' then c_state <= s_ack_a;
                        else c_state <= idle;
                        end if;
                        ictrl <= ictrl;
                    -- start
                    when start_a =>
                        c_state <= start_b;
                        ictrl <= ( '1' & ictrl(2) & "11" );                        
                    when start_b =>
                        c_state <= start_c;
                        ictrl <= "1111";                    
                    when start_c =>
                        c_state <= start_d;
                        ictrl <= "1101";                     
                    when start_d =>
                        c_state <= start_e;
                        ictrl <= "1101";                        
                    when start_e =>
                        c_state <= start_f;
                        ictrl <= "1100";
                    when start_f =>
                        c_state <= idle;
                        bit_done <= '1';
                        ictrl <= "1100";
                    -- stop
                    when stop_a =>
                        c_state <= stop_b;
                        ictrl <= "1100";                        
                    when stop_b =>
                        c_state <= stop_c;
                        ictrl <= "1101";                    
                    when stop_c =>
                        c_state <= stop_d;
                        ictrl <= "1101";                     
                    when stop_d =>
                        c_state <= stop_e;
                        ictrl <= "1111";
                    when stop_e =>
                        c_state <= idle;
                        bit_done <= '1';
                        ictrl <= "1111";
                    -- write
                    when wr_a =>
                        c_state <= wr_b;
                        ictrl <= ( "11" & din & '0' );                        
                    when wr_b =>
                        c_state <= wr_c;
                        ictrl <= ( "11" & din & '1' );                    
                    when wr_c =>
                        c_state <= wr_d;
                        ictrl <= ( "11" & din & '1' );                       
                    when wr_d =>
                        c_state <= wr_e;
                        ictrl <= ( "11" & din & '0' );
                    when wr_e =>
                        c_state <= idle;
                        bit_done <= '1';
                        ictrl <= ( "11" & din & '0' );
                    -- s_sck
                    when s_ack_a =>
                        c_state <= s_ack_b;
                        ictrl <= "0011";                        
                    when s_ack_b =>
                        c_state <= s_ack_c;
                        ictrl <= "0011";                    
                    when s_ack_c =>
                        c_state <= s_ack_d;
                        ictrl <= "0011";                       
                    when s_ack_d =>
                        c_state <= s_ack_e;
                        ictrl <= "0011";                       
                    when s_ack_e =>
                        c_state <= idle;
                        bit_done <= '1';
                        ictrl <= "1100";
                    when others =>
                end case;
            end if;
        end if;
    end process next_state_decoder_proc;
    
--    signal ictrl:            std_logic_vector( 3 downto 0 ); -- internal control, 0 = scl_c, 1 = sda_o, 2 = scl_oen, 3 = sda_oen
    scl_o <= ictrl(0);
    sda_o <= ictrl(1);
    scl_oen <= ictrl(2);
    sda_oen <= ictrl(3);

    dly_scl_proc: process( clk )
    begin
        if rising_edge( clk ) then d_scl_i <= scl_i;
        end if;
    end process dly_scl_proc;
    
    -- capture slave ack
    slave_ack_proc: process( clk, rst )
    begin
        if rst = '1' then
            ack_out <= '0';
        elsif rising_edge( clk ) then
            if( ( ( c_state = s_ack_a ) or
                  ( c_state = s_ack_b ) or
                  ( c_state = s_ack_c ) or
                  ( c_state = s_ack_d ) ) and
                  ( scl_i = '1' ) and
                  ( d_scl_i = '0' ) and
                  ( sda_i = '0' ) ) then
                  ack_out <= '1';
            else ack_out <= '0';
            end if;
        end if; 
    end process slave_ack_proc;
    
end Behavioral;
