----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2023/07/14 18:08:21
-- Design Name: 
-- Module Name: iic_byte_ctrl_v2 - Behavioral
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

entity iic_byte_ctrl_v2 is
Port (
        clk:        in std_logic;
        rst:        in std_logic;
        
        clk_cnt:    in unsigned( 15 downto 0 ) := x"000F";
        
        -- input signal
        
        byte_sta:       in std_logic;
        byte_wr:        in std_logic;
        byte_sto:       in std_logic;
        byte_din:       in std_logic_vector( 7 downto 0 );        
        
        -- output
        ack_out:        out std_logic;
        busy:           out std_logic;
        byte_done:      out std_logic;
        
            -- iic lines --
            scl_i:          in std_logic;
            scl_o:          out std_logic;
            scl_oen:        out std_logic;
            sda_i:          in std_logic;
            sda_o:          out std_logic;
            sda_oen:        out std_logic

);
end iic_byte_ctrl_v2;

architecture Behavioral of iic_byte_ctrl_v2 is

    component iic_bit_ctrl_v2 is
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
    end component iic_bit_ctrl_v2;

    type states is ( idle,
            start, sd_b1, sd_b2, sd_b3, sd_b4, sd_b5, sd_b6, sd_b7, sd_b8, s_ack_b9, stop, st_done, st_wait
              );

    signal c_state:     states := idle;
    
    signal ibit_done:       std_logic;

       signal sta:         std_logic;
       signal wr:         std_logic;
       signal sto:         std_logic;
       signal s_ack:         std_logic;
       signal bit_done:     std_logic;
       signal din:          std_logic;
       
       signal st_wait_cnt:      unsigned( 3 downto 0 ) := ( others => '1' );
begin

    uiic_bit_ctrl: iic_bit_ctrl_v2
    Port map(
        clk => clk,
        rst => rst,
        
        clk_cnt => clk_cnt,
        
        -- input signal
        sta => sta,
        wr => wr,
        sto => sto,
        s_ack => s_ack,
    --    m_ack:        in std_logic;
    --    m_inv_ack:        in std_logic;
        din => din,
        
        -- output
        ack_out => ack_out,
        busy => busy,
        bit_done => ibit_done,
        
            -- iic lines --
            scl_i => scl_i,
            scl_o => scl_o,
            scl_oen => scl_oen,
            sda_i => sda_i,
            sda_o => sda_o,
            sda_oen => sda_oen
     );
 
    bit_done <= ibit_done;
 
    st_wait_proc: process( clk, rst )
    begin
        if rst = '1' then
            st_wait_cnt <= ( others => '1' );
        elsif rising_edge( clk ) then
            if( c_state = st_wait ) then st_wait_cnt <= st_wait_cnt - 1;
            else st_wait_cnt <= ( others => '1' );
            end if;
        end if;
    end process st_wait_proc;
 
    state_proc: process( clk, rst )
    begin
        if rst = '1' then
            c_state <= idle;
            sta <= '0';
            wr <= '0';
            sto <= '0';
            s_ack <= '0';
            byte_done <= '0';
        elsif rising_edge( clk ) then
            byte_done <= '0';
            if ibit_done = '1' then
                sta <= '0';
                wr <= '0';
                sto <= '0';
                s_ack <= '0';
                case c_state is
                    when sd_b1 =>
                        c_state <= sd_b2;
                        wr <= '1';
                        din <= byte_din(7);
                    when sd_b2 =>
                        c_state <= sd_b3;
                        wr <= '1';
                        din <= byte_din(6);
                    when sd_b3 =>
                        c_state <= sd_b4;
                        wr <= '1';
                        din <= byte_din(5);
                    when sd_b4 =>
                        c_state <= sd_b5;
                        wr <= '1';
                        din <= byte_din(4);
                   when sd_b5 =>
                        c_state <= sd_b6;
                        wr <= '1';
                        din <= byte_din(3);
                    when sd_b6 =>
                        c_state <= sd_b7;
                        wr <= '1';
                        din <= byte_din(2);
                    when sd_b7 =>
                        c_state <= sd_b8;
                        wr <= '1';
                        din <= byte_din(1);
                    when sd_b8 =>
                        c_state <= s_ack_b9;
                        wr <= '1';
                        din <= byte_din(0);
                    when s_ack_b9 =>
                        if byte_sto = '1' then c_state <= stop;
                        else
                            c_state <= st_done;
                        end if;
                        s_ack <= '1';
                    when stop =>
                        c_state <= st_done;
                        sto <= '1';
                    when st_done =>
                        c_state <= st_wait;
                        byte_done <= '1';
                    when others =>
                        c_state <= idle;
                end case;
            elsif c_state = st_wait then        -- wait few cycle to let bit change in up stream
                if st_wait_cnt = 0 then c_state <= idle;
                end if;
            elsif c_state = idle then
                if byte_sta = '1' then
                    c_state <= sd_b1;
                    sta <= '1';
                elsif byte_wr = '1' then
                    c_state <= sd_b2;
                    wr <= '1';
                    din <= byte_din(7);
                end if;
            end if;
        end if;
    end process state_proc;
 
 
 
end Behavioral;
