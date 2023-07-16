----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2023/07/16 08:25:26
-- Design Name: 
-- Module Name: top_module_v3 - Behavioral
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

entity top_module_v3 is
Port (
            clk:            in std_logic;
            rst:            in std_logic;
            
            t_node:         out std_logic_vector( 1 downto 0 );
            iic_led:        out std_logic;
 
            ssm_mclk :		out std_logic;
            ssm_bclk :		out std_logic;
            ssm_pblrc :		out std_logic;
            ssm_pbdat :		out std_logic;
            ssm_reclrc :	out std_logic;
            ssm_recdat :	in std_logic;
            ssm_muten :		out std_logic;

            aud_out:		in std_logic;
            clip_aud:       in std_logic; 
            
            rec_aud:        in std_logic;
            rec_led:        out std_logic;
            play_aud:       in std_logic;
            play_led:       out std_logic;
                          
            ssm_scl:        inout std_logic;
            ssm_sda:        inout std_logic
 );
end top_module_v3;

architecture Behavioral of top_module_v3 is

    component iic_top_v2  is
    Port (
                clk:            in std_logic;
                rst:            in std_logic;
                
                ack_out:        out std_logic;
                    
                ssm_scl:        inout std_logic;
                ssm_sda:        inout std_logic
     );
    end component iic_top_v2; 

    component clk_wiz_0 is
    port(
        clk_in1:        in std_logic;
        clk_out1:       out std_logic;
        clk_out2:       out std_logic
    );
    end component clk_wiz_0;

    signal clk_24Mhz:       std_logic;
    signal clk_5Mhz:        std_logic;
    signal ack_out:         std_logic;
    signal iled_o:          std_logic;

    component EDGE_DETECT is
        Port (
            clk : in std_logic;
            rst : in std_logic;
            signal_in : in std_logic;
            pos_edge : out std_logic;
            neg_edge : out std_logic
            );
    end component EDGE_DETECT;

    signal mclk_buf:        std_logic := '0';
	signal bck_buf:        unsigned( 2 downto 0 ) := "000";
	signal lrck_buf:       unsigned( 8 downto 0 ) := "000000000";
	
            -- state machine
            type i2s_states is ( idle, 
                    l_st, l_cap, r_st, r_cap
                    );
            signal i2s_state:       i2s_states := idle;
	
       signal l_dat_in:     std_logic_vector( 23 downto 0 ) := ( others => '0' );
       signal r_dat_in:     std_logic_vector( 23 downto 0 ) := ( others => '0' );
       signal l_dat_out:    std_logic_vector( 23 downto 0 ) := ( others => '0' );
       signal r_dat_out:    std_logic_vector( 23 downto 0 ) := ( others => '0' );
       
       signal lr_neg, lr_pos, bck_pos, bck_neg:      std_logic;
       signal cap_cnt:                              natural := 23;
       signal sd_dac:                               std_logic;

        component blk_mem_gen_0 IS
          PORT (
            clka :  IN STD_LOGIC;
            ena :   IN STD_LOGIC;
            wea :   IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(18 DOWNTO 0);
            dina :  IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
          );
        END component blk_mem_gen_0;
        
        signal blk_addr:        unsigned( 18 downto 0 ) := ( others => '0' );
        signal blk_din:         std_logic_vector( 15 downto 0 ) := x"0000";
        signal blk_dout:        std_logic_vector( 15 downto 0 ) := x"0000";
        signal blk_wr:          std_logic_vector( 0 downto 0 ) := "0";
        signal iblk_wr:         std_logic := '0';
        signal iblk_rd:         std_logic := '0';

begin

    ublk_mem_gen: blk_mem_gen_0
    port map(
        clka => clk_24Mhz,
        ena => '1',
        wea => blk_wr,
        addra => std_logic_vector(blk_addr),
        dina => std_logic_vector(blk_din),
        douta => blk_dout
    );

    uclk_wiz:   clk_wiz_0
    port map(
        clk_in1 => clk,
        clk_out1 => clk_24Mhz,
        clk_out2 => clk_5Mhz    
    );

    uiic_top: iic_top_v2
    port map(
                clk => clk_5Mhz,
                rst => rst,
                
                ack_out => ack_out,
                    
                ssm_scl => ssm_scl,
                ssm_sda => ssm_sda
    );

    led_o_proc: process( clk_5Mhz, rst )
    begin
        if rst = '1' then iled_o <= '0';
        elsif rising_edge( clk_5Mhz ) then
            if ack_out = '1' then iled_o <= not iled_o;
            end if;
        end if;
    end process led_o_proc;
    
    iic_led <= iled_o;
    

	ssm_clk_gen_proc: process( rst, clk_24Mhz ) is
	begin
	   if rst = '1'  then
            bck_buf <= "000";
            lrck_buf <= "000000000";
            mclk_buf <= '0';	       
       elsif( rising_edge ( clk_24Mhz ) ) then
            bck_buf <= bck_buf + "1";
            lrck_buf <= lrck_buf + "1";
            mclk_buf <= not mclk_buf;
       end if;
	end process ssm_clk_gen_proc;

    ulr_edge_detect: EDGE_DETECT
    port map(
            clk => clk_24Mhz,
            rst => rst,
            signal_in => lrck_buf(8),
            pos_edge => lr_pos,
            neg_edge => lr_neg
    );
    
    ubck_edge_detect: EDGE_DETECT
    port map(
            clk => clk_24Mhz,
            rst => rst,
            signal_in => bck_buf(2),
            pos_edge => bck_pos,
            neg_edge => bck_neg
    );

    cap_dat_proc: process( clk_24Mhz, rst )
    begin
        if rst = '1' then
            i2s_state <= idle;
            cap_cnt <= 23;
            blk_wr <= "0";
        elsif rising_edge( clk_24Mhz ) then
            blk_wr <= "0";
            if lr_neg = '1' then
                i2s_state <= l_st;
                cap_cnt <= 23;
            elsif lr_pos = '1' then
                i2s_state <= r_st;
                cap_cnt <= 23;
            elsif bck_pos = '1' then
                case i2s_state is
                    when l_st =>
                        i2s_state <= l_cap;
                        if iblk_wr = '1' then
                            blk_din <= l_dat_in ( 23 downto 8 );
                            l_dat_out <= l_dat_in;
                            blk_wr <= "1";
                        elsif iblk_rd = '1' then
                            l_dat_out <= ( blk_dout & "00000000" );
                        else l_dat_out <= l_dat_in;
                        end if;
                        if clip_aud = '1' then
                            if( l_dat_out > x"EFFFFF" ) then l_dat_out <= x"EFFFFF";
                            elsif( l_dat_out < x"0FFFFF" ) then l_dat_out <= x"0FFFFF";
                            end if;                 
                        end if;
                    when r_st =>
                        i2s_state <= r_cap;
                        if iblk_rd = '1' then
                            r_dat_out <= ( blk_dout & "00000000" );
                        else r_dat_out <= r_dat_in;
                        end if;
                        if clip_aud = '1' then
                            if( r_dat_out > x"EFFFFF" ) then r_dat_out <= x"EFFFFF";
                            elsif( r_dat_out < x"0FFFFF" ) then r_dat_out <= x"0FFFFF";
                            end if;
                        else r_dat_out <= r_dat_in;
                        end if;
                    when l_cap =>
                        if cap_cnt >= 0 then
                            l_dat_in( cap_cnt ) <= ssm_recdat;
                            cap_cnt <= cap_cnt - 1;
                        end if;
                    when r_cap =>
                        if cap_cnt >= 0 then
                            r_dat_in( cap_cnt ) <= ssm_recdat;
                            cap_cnt <= cap_cnt - 1;
                        end if;
                    when others =>
                end case;
            elsif bck_neg = '1' then
                if aud_out = '1' or iblk_rd = '1' then
                    case i2s_state is
                        when l_st => if cap_cnt >= 0 then sd_dac <= l_dat_out( cap_cnt ); end if;
                        when l_cap => if cap_cnt >= 0 then sd_dac <= l_dat_out( cap_cnt ); end if;
                        when r_st => if cap_cnt >= 0 then sd_dac <= r_dat_out( cap_cnt ); end if;
                        when r_cap => if cap_cnt >= 0 then sd_dac <= r_dat_out( cap_cnt ); end if;
                        when others =>
                    end case;
                end if;
             end if;
        end if;
    end process cap_dat_proc;
    
    blk_mem_proc: process( clk_24Mhz, rst )
    begin
        if rst = '1' then
            iblk_wr <= '1';
            iblk_rd <= '0';
            blk_addr <= ( others => '0' );
        elsif rising_edge( clk_24Mhz ) then
            if iblk_wr = '1' then
                if lr_neg = '1' then
                    if blk_addr < x"45600" then
                        blk_addr <= blk_addr + 1;
                    else
                        blk_addr <= ( others => '0' );
                        iblk_wr <= '0';
                    end if;
                end if;
            elsif iblk_rd = '1' then
                if lr_neg = '1' then
                    if blk_addr < x"45600" then
                        blk_addr <= blk_addr + 1;
                    else
                        blk_addr <= ( others => '0' );
                        iblk_rd <= '0';
                    end if;
                end if;
            elsif rec_aud = '1' then
                iblk_wr <= '1';
                blk_addr <= ( others => '0' );
            elsif play_aud = '1' then
                iblk_rd <= '1';
                blk_addr <= ( others => '0' );
            end if;
        end if;
                
    end process blk_mem_proc;
    
        rec_led <= iblk_wr;
        play_led <= iblk_rd;

            ssm_mclk <= mclk_buf;
            ssm_bclk <= bck_buf(2);
            ssm_pblrc <= lrck_buf(8);
            ssm_pbdat <= sd_dac;
            ssm_reclrc <= lrck_buf(8);
            t_node(1) <= ssm_recdat;
            t_node(0) <= bck_buf(2);
            ssm_muten <= '1';

end Behavioral;