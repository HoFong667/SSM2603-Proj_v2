----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2023/07/14 20:02:11
-- Design Name: 
-- Module Name: iic_top_v2 - Behavioral
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

entity iic_top_v2  is
Port (
            clk:            in std_logic;
            rst:            in std_logic;
            
            ack_out:        out std_logic;
                
            ssm_scl:        inout std_logic;
            ssm_sda:        inout std_logic
 );
end iic_top_v2; 

architecture Behavioral of iic_top_v2  is

    constant iic_addr:                  std_logic_vector( 7 downto 0 ) := "00110100";                   -- addr 0011 010 + wr 0

    constant iic_r15_software_rst:      std_logic_vector( 6 downto 0 ) := "0001111";
    constant iic_r15_dat:               std_logic_vector( 8 downto 0 ) := "000000000";

    constant iic_r0_adc_vol:            std_logic_vector( 6 downto 0 ) := "0000000";
    constant iic_r0_dat:                std_logic_vector( 8 downto 0 ) := "000010111";

    constant iic_r1_adc_vol:            std_logic_vector( 6 downto 0 ) := "0000001";
    constant iic_r1_dat:                std_logic_vector( 8 downto 0 ) := "000010111";
    
    constant iic_r2_dac_vol:            std_logic_vector( 6 downto 0 ) := "0000010";
    constant iic_r2_dat:                std_logic_vector( 8 downto 0 ) := "101111001";

    constant iic_r3_dac_vol:            std_logic_vector( 6 downto 0 ) := "0000011";
    constant iic_r3_dat:                std_logic_vector( 8 downto 0 ) := "101111001";

    constant iic_r4_analog_path:        std_logic_vector( 6 downto 0 ) := "0000100";
--    constant iic_r4_dat:                std_logic_vector( 8 downto 0 ) := "000000000";    -- original in initial
    constant iic_r4_dat:                std_logic_vector( 8 downto 0 ) := "000010010";    -- set line input
--    constant iic_r4_dat:                std_logic_vector( 8 downto 0 ) := "000010110";    -- set HpOut

    constant iic_r5_digit_path:         std_logic_vector( 6 downto 0 ) := "0000101";
    constant iic_r5_dat:                std_logic_vector( 8 downto 0 ) := "000000000";
    
    constant iic_r6_pow_mgmt:           std_logic_vector( 6 downto 0 ) := "0000110";
    constant iic_r6_dat_1:              std_logic_vector( 8 downto 0 ) := "000110000";
    constant iic_r6_dat_2:              std_logic_vector( 8 downto 0 ) := "000100000";
    
    constant iic_r7_digit_if:           std_logic_vector( 6 downto 0 ) := "0000111";
    constant iic_r7_dat:                std_logic_vector( 8 downto 0 ) := "000001010";

    constant iic_r8_sample_rate:        std_logic_vector( 6 downto 0 ) := "0001000";
    constant iic_r8_dat:                std_logic_vector( 8 downto 0 ) := "000000000";

    constant iic_r9_active:             std_logic_vector( 6 downto 0 ) := "0001001";
    constant iic_r9_dat:                std_logic_vector( 8 downto 0 ) := "000000001";

    component iic_byte_ctrl_v2 is
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
    end component iic_byte_ctrl_v2;

    component cycle_delay is
    Port (
        rst_i:      in std_logic;
        clk_i:      in std_logic;
        signal_i:   in std_logic;
        delay_o:    out std_logic
    );
    
    end component cycle_delay;

    component EDGE_DETECT is
        Port (
            clk : in std_logic;
            rst : in std_logic;
            signal_in : in std_logic;
            pos_edge : out std_logic;
            neg_edge : out std_logic
            );
    end component EDGE_DETECT;

            signal    scl_o:           std_logic;
            signal    scl_oen:         std_logic;

             signal   sda_o:           std_logic;
             signal   sda_oen:         std_logic;

            signal byte_din:          std_logic_vector( 7 downto 0 );
            signal sta_wr_sto_pin:       std_logic_vector( 2 downto 0 );     -- 2-sta / 1-wr / 0-sto
    
            -- output
            signal busy:            std_logic;
            signal byte_done:       std_logic;

            -- state machine
            type states is ( idle,
                    sw_rst_a, sw_rst_b, sw_rst_c, sw_rst_d,
                    pw_mgm1_a, pw_mgm1_b, pw_mgm1_c, pw_mgm1_d,
                    l_adc_a, l_adc_b, l_adc_c, l_adc_d,
                    r_adc_a, r_adc_b, r_adc_c, r_adc_d,
                    l_dac_a, l_dac_b, l_dac_c, l_dac_d,
                    r_dac_a, r_dac_b, r_dac_c, r_dac_d,
                    analog_a, analog_b, analog_c, analog_d,
                    digit_a, digit_b, digit_c, digit_d, 
                    di_if_a, di_if_b, di_if_c, di_if_d, 
                    sam_r_a, sam_r_b, sam_r_c, sam_r_d,
                    act_a, act_b, act_c, act_d,
                    pw_mgm2_a, pw_mgm2_b, pw_mgm2_c, pw_mgm2_d,
                    st_wait
                    );

            signal c_state:     states := idle;
            
            signal dly_o:          std_logic;
            signal st_waiting:     std_logic;
            signal st_waiting2:    std_logic;

        

begin

    st_waiting_proc:    process( clk, rst )
    begin
        if rst = '1' then
            st_waiting <= '0';
        elsif rising_edge( clk ) then
            if( ( c_state = sw_rst_d ) or
                ( c_state = pw_mgm1_d ) or
                ( c_state = l_adc_d ) or
                ( c_state = r_adc_d ) or
                ( c_state = l_dac_d ) or
                ( c_state = r_dac_d ) or
                ( c_state = analog_d ) or
                ( c_state = digit_d ) or
                ( c_state = di_if_d ) or
                ( c_state = sam_r_d ) or
                ( c_state = act_d ) or
                ( c_state = pw_mgm2_d )
                 ) then
                st_waiting <= '1';
            else
                st_waiting <= '0';
            end if;
        end if;
    end process st_waiting_proc;
    st_waiting2 <= not st_waiting;
    
    udly: cycle_delay
    port map(
        clk_i => clk,
        rst_i => st_waiting2,
        signal_i => st_waiting,
        delay_o => dly_o
    );

    uiic_byte_ctrl: iic_byte_ctrl_v2
    Port map(
                clk => clk,
                rst => rst,
                
                clk_cnt => x"0008",     -- 12.5us period
                
                -- input signal
                byte_sta => sta_wr_sto_pin(2),
                byte_wr => sta_wr_sto_pin(1),
                byte_sto => sta_wr_sto_pin(0),
                byte_din => byte_din,
                
                -- output
                ack_out => ack_out,
                busy => busy,
                byte_done => byte_done,
                
                -- iic lines --
                scl_i => ssm_scl,
                scl_o => scl_o,
                scl_oen => scl_oen,
                sda_i => ssm_sda,
                sda_o => sda_o,
                sda_oen => sda_oen
     );

    state_ctrl_proc: process( clk, rst )
    begin
        if rst = '1' then
            c_state <= idle;
            sta_wr_sto_pin <= "000";
            byte_din <= x"00";
        elsif rising_edge( clk ) then
            case c_state is
                when idle =>
                
                    -- software rst
                    c_state <= sw_rst_a;
                    sta_wr_sto_pin <= "100";
                    byte_din <= iic_addr;
                when sw_rst_a =>
                    if byte_done = '1' then
                        c_state <= sw_rst_b;
                        sta_wr_sto_pin <= "010";
                        byte_din <= ( iic_r15_software_rst & iic_r15_dat(8) );
                    end if;
                when sw_rst_b =>
                    if byte_done = '1' then
                        c_state <= sw_rst_c;
                        sta_wr_sto_pin <= "011";
                        byte_din <= iic_r15_dat( 7 downto 0 );
                    end if;
                when sw_rst_c =>
                    if byte_done = '1' then
                        c_state <= sw_rst_d;        -- do noting but wait
                        sta_wr_sto_pin <= "000";
                        byte_din <= x"00";
                    end if;
                when sw_rst_d =>
                    if dly_o = '1' then
                    
                        -- power mgm1
                        c_state <= pw_mgm1_a;
                        sta_wr_sto_pin <= "100";
                        byte_din <= iic_addr;
                    end if;
                when pw_mgm1_a =>
                    if byte_done = '1' then
                        c_state <= pw_mgm1_b;
                        sta_wr_sto_pin <= "010";
                        byte_din <= ( iic_r6_pow_mgmt & iic_r6_dat_1(8) );
                    end if;
                when pw_mgm1_b =>
                    if byte_done = '1' then
                        c_state <= pw_mgm1_c;
                        sta_wr_sto_pin <= "011";
                        byte_din <= iic_r6_dat_1( 7 downto 0 );
                    end if;
                when pw_mgm1_c =>
                    if byte_done = '1' then
                        c_state <= pw_mgm1_d;
                        sta_wr_sto_pin <= "000";
                        byte_din <= x"00";
                    end if;
                when pw_mgm1_d =>
                    if dly_o = '1' then
                    
                        -- left adc
                        c_state <= l_adc_a;
                        sta_wr_sto_pin <= "100";
                        byte_din <= iic_addr;
                    end if;
                when l_adc_a =>
                    if byte_done = '1' then
                        c_state <= l_adc_b;
                        sta_wr_sto_pin <= "010";
                        byte_din <= ( iic_r0_adc_vol & iic_r0_dat(8) );
                    end if;
                when l_adc_b =>
                    if byte_done = '1' then
                        c_state <= l_adc_c;
                        sta_wr_sto_pin <= "011";
                        byte_din <= iic_r0_dat( 7 downto 0 );
                    end if;
                when l_adc_c =>
                    if byte_done = '1' then
                        c_state <= l_adc_d;
                        sta_wr_sto_pin <= "000";
                        byte_din <= x"00";
                    end if;
                when l_adc_d =>
                    if dly_o = '1' then
                    
                        -- right adc
                        c_state <= r_adc_a;
                        sta_wr_sto_pin <= "100";
                        byte_din <= iic_addr;
                    end if;
                when r_adc_a =>
                    if byte_done = '1' then
                        c_state <= r_adc_b;
                        sta_wr_sto_pin <= "010";
                        byte_din <= ( iic_r1_adc_vol & iic_r1_dat(8) );
                    end if;
                when r_adc_b =>
                    if byte_done = '1' then
                        c_state <= r_adc_c;
                        sta_wr_sto_pin <= "011";
                        byte_din <= iic_r1_dat( 7 downto 0 );
                    end if;
                when r_adc_c =>
                    if byte_done = '1' then
                        c_state <= r_adc_d;
                        sta_wr_sto_pin <= "000";
                        byte_din <= x"00";
                    end if;
                when r_adc_d =>
                    if dly_o = '1' then
                    
                        -- left dac
                        c_state <= l_dac_a;
                        sta_wr_sto_pin <= "100";
                        byte_din <= iic_addr;
                    end if;
                when l_dac_a =>
                    if byte_done = '1' then
                        c_state <= l_dac_b;
                        sta_wr_sto_pin <= "010";
                        byte_din <= ( iic_r2_dac_vol & iic_r2_dat(8) );
                    end if;
                when l_dac_b =>
                    if byte_done = '1' then
                        c_state <= l_dac_c;
                        sta_wr_sto_pin <= "011";
                        byte_din <= iic_r2_dat( 7 downto 0 );
                    end if;
                when l_dac_c =>
                    if byte_done = '1' then
                        c_state <= l_dac_d;
                        sta_wr_sto_pin <= "000";
                        byte_din <= x"00";
                    end if;
                when l_dac_d =>
                    if dly_o = '1' then
                    
                        -- right dac
                        c_state <= r_dac_a;
                        sta_wr_sto_pin <= "100";
                        byte_din <= iic_addr;
                    end if;
                when r_dac_a =>
                    if byte_done = '1' then
                        c_state <= r_dac_b;
                        sta_wr_sto_pin <= "010";
                        byte_din <= ( iic_r3_dac_vol & iic_r3_dat(8) );
                    end if;
                when r_dac_b =>
                    if byte_done = '1' then
                        c_state <= r_dac_c;
                        sta_wr_sto_pin <= "011";
                        byte_din <= iic_r3_dat( 7 downto 0 );
                    end if;
                when r_dac_c =>
                    if byte_done = '1' then
                        c_state <= r_dac_d;
                        sta_wr_sto_pin <= "000";
                        byte_din <= x"00";
                    end if;
                when r_dac_d =>
                    if dly_o = '1' then
                    
                        -- analog path
                        c_state <= analog_a;
                        sta_wr_sto_pin <= "100";
                        byte_din <= iic_addr;
                    end if;
                when analog_a =>
                    if byte_done = '1' then
                        c_state <= analog_b;
                        sta_wr_sto_pin <= "010";
                        byte_din <= ( iic_r4_analog_path & iic_r4_dat(8) );
                    end if;
                when analog_b =>
                    if byte_done = '1' then
                        c_state <= analog_c;
                        sta_wr_sto_pin <= "011";
                        byte_din <= iic_r4_dat( 7 downto 0 );
                    end if;
                when analog_c =>
                    if byte_done = '1' then
                        c_state <= analog_d;
                        sta_wr_sto_pin <= "000";
                        byte_din <= x"00";
                    end if;
                when analog_d =>
                    if dly_o = '1' then
                    
                        -- digitial path
                        c_state <= digit_a;
                        sta_wr_sto_pin <= "100";
                        byte_din <= iic_addr;
                    end if;
                when digit_a =>
                    if byte_done = '1' then
                        c_state <= digit_b;
                        sta_wr_sto_pin <= "010";
                        byte_din <= ( iic_r5_digit_path & iic_r5_dat(8) );
                    end if;
                when digit_b =>
                    if byte_done = '1' then
                        c_state <= digit_c;
                        sta_wr_sto_pin <= "011";
                        byte_din <= iic_r5_dat( 7 downto 0 );
                    end if;
                when digit_c =>
                    if byte_done = '1' then
                        c_state <= digit_d;
                        sta_wr_sto_pin <= "000";
                        byte_din <= x"00";
                    end if;
                when digit_d =>
                    if dly_o = '1' then
                    
                        -- digitial IF
                        c_state <= di_if_a;
                        sta_wr_sto_pin <= "100";
                        byte_din <= iic_addr;
                    end if;
                when di_if_a =>
                    if byte_done = '1' then
                        c_state <= di_if_b;
                        sta_wr_sto_pin <= "010";
                        byte_din <= ( iic_r7_digit_if & iic_r7_dat(8) );
                    end if;
                when di_if_b =>
                    if byte_done = '1' then
                        c_state <= di_if_c;
                        sta_wr_sto_pin <= "011";
                        byte_din <= iic_r7_dat( 7 downto 0 );
                    end if;
                when di_if_c =>
                    if byte_done = '1' then
                        c_state <= di_if_d;
                        sta_wr_sto_pin <= "000";
                        byte_din <= x"00";
                    end if;
                when di_if_d =>
                    if dly_o = '1' then

                        -- sampling rate
                        c_state <= sam_r_a;
                        sta_wr_sto_pin <= "100";
                        byte_din <= iic_addr;
                    end if;
                when sam_r_a =>
                    if byte_done = '1' then
                        c_state <= sam_r_b;
                        sta_wr_sto_pin <= "010";
                        byte_din <= ( iic_r8_sample_rate & iic_r8_dat(8) );
                    end if;
                when sam_r_b =>
                    if byte_done = '1' then
                        c_state <= sam_r_c;
                        sta_wr_sto_pin <= "011";
                        byte_din <= iic_r8_dat( 7 downto 0 );
                    end if;
                when sam_r_c =>
                    if byte_done = '1' then
                        c_state <= sam_r_d;
                        sta_wr_sto_pin <= "000";
                        byte_din <= x"00";
                    end if;
                when sam_r_d =>
                    if dly_o = '1' then

                        -- active
                        c_state <= act_a;
                        sta_wr_sto_pin <= "100";
                        byte_din <= iic_addr;
                    end if;
                when act_a =>
                    if byte_done = '1' then
                        c_state <= act_b;
                        sta_wr_sto_pin <= "010";
                        byte_din <= ( iic_r9_active & iic_r9_dat(8) );
                    end if;
                when act_b =>
                    if byte_done = '1' then
                        c_state <= act_c;
                        sta_wr_sto_pin <= "011";
                        byte_din <= iic_r9_dat( 7 downto 0 );
                    end if;
                when act_c =>
                    if byte_done = '1' then
                        c_state <= act_d;
                        sta_wr_sto_pin <= "000";
                        byte_din <= x"00";
                    end if;
                when act_d =>
                    if dly_o = '1' then
                   
                        -- power management 2
                        c_state <= pw_mgm2_a;
                        sta_wr_sto_pin <= "100";
                        byte_din <= iic_addr;
                    end if;
                when pw_mgm2_a =>
                    if byte_done = '1' then
                        c_state <= pw_mgm2_b;
                        sta_wr_sto_pin <= "010";
                        byte_din <= ( iic_r6_pow_mgmt & iic_r6_dat_2(8) );
                    end if;
                when pw_mgm2_b =>
                    if byte_done = '1' then
                        c_state <= pw_mgm2_c;
                        sta_wr_sto_pin <= "011";
                        byte_din <= iic_r6_dat_2( 7 downto 0 );
                    end if;
                when pw_mgm2_c =>
                    if byte_done = '1' then
                        c_state <= pw_mgm2_d;
                        sta_wr_sto_pin <= "000";
                        byte_din <= x"00";
                    end if;
                when pw_mgm2_d =>
                    if dly_o = '1' then
                        c_state <= st_wait;
                    end if;
                when others =>
            end case;
        end if;
    end process state_ctrl_proc;

    ssm_scl <= scl_o when scl_oen = '1' else 'Z';
    ssm_sda <= sda_o when sda_oen = '1' else 'Z';


end Behavioral;
