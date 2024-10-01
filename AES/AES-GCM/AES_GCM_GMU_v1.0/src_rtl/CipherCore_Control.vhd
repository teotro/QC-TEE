-------------------------------------------------------------------------------
--! @file       CipherCore_Control.vhd
--! @author     Ekawat (ice) Homsirikamol
--! @brief      Control unit for AES-GCM
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.AEAD_pkg.all;

entity CipherCore_Control is
    generic (
        G_MAX_LEN       : integer := SINGLE_PASS_MAX
    );
    port (
        clk             : in  std_logic;
        rst             : in  std_logic;

        --! Input
        key_ready       : out std_logic;
        key_valid       : in  std_logic;
        key_update      : in  std_logic;

        mode            : in  std_logic;
        bdi_ready       : out std_logic;
        bdi_valid       : in  std_logic;
        bdi_type        : in  std_logic_vector(3                -1 downto 0);
        bdi_eot         : in  std_logic;
        bdi_eoi         : in  std_logic;
        bdi_size        : in  std_logic_vector(5                -1 downto 0);

        --! Datapath
        len_a           : out std_logic_vector(G_MAX_LEN        -1 downto 0);
        len_d           : out std_logic_vector(G_MAX_LEN        -1 downto 0);
        aes_done        : in  std_logic;
        mult_done       : in  std_logic;
        en_key          : out std_logic;
        en_hashkey      : out std_logic;
        en_npub         : out std_logic;
        en_ctr          : out std_logic;
        en_aes          : out std_logic;
        en_mult         : out std_logic;
        clr_hashkey     : out std_logic;
        clr_ctr         : out std_logic;
        clr_mult        : out std_logic;
        sel_tag         : out std_logic;
        sel_mux1        : out std_logic;
        sel_mux2        : out std_logic_vector(2                -1 downto 0);
        sel_aes         : out std_logic;
        msg_auth_done   : out std_logic;

        --! Output
        bdo_ready       : in  std_logic;
        bdo_valid       : out std_logic
    );
end entity CipherCore_Control;

architecture behavior of CipherCore_Control is
    --! Note: Split LDKEY into two sub states as we still haven't occupied
    --! all the STATE bits yet (4-bit).

    type state_type is (
        S_INIT,             S_KEY_CHECK,
        S_LDKEY_1,          S_LDKEY_2,
        S_LDKEY_3,          S_LDKEY_4,
        S_SETUP_H_PRE,      S_WAIT_NPUB,
        S_SETUP_H,          S_AUTH_WAIT_DATA,
        S_AUTH_WAIT_MULT,   S_DATA_WAIT_AES,
        S_START_EK0,
        S_MULT_LEN,         S_TAG_OUT);
    signal state, nstate   : state_type;

    signal aes_busy       : std_logic;
    signal mult_busy      : std_logic;

    signal set_init_ad    : std_logic;
    signal clr_init_ad    : std_logic;

    signal en_aes_s       : std_logic;
    signal en_mult_s      : std_logic;
    signal bdi_rdy        : std_logic;
    signal bdo_vld        : std_logic;
    signal is_decrypt     : std_logic;
    
    --! Note: Data represented in byte
    signal len_a_r        : std_logic_vector(G_MAX_LEN-3     -1 downto 0);
    signal len_d_r        : std_logic_vector(G_MAX_LEN-3     -1 downto 0);
begin
    en_aes   <= en_aes_s;
    en_mult  <= en_mult_s;
    bdi_ready <= bdi_rdy;
    bdo_valid <= bdo_vld;

    p_reg:
    process( clk )
    begin
        if rising_edge( clk ) then
            if rst = '1' then
                state         <= S_INIT;
                aes_busy      <= '0';
                mult_busy     <= '0';
                sel_mux1      <= '1';
            else
                state <= nstate;

                if aes_done = '1' then
                    aes_busy <= '0';
                elsif en_aes_s = '1' then
                    aes_busy <= '1';
                end if;

                if mult_done = '1' then
                    mult_busy <= '0';
                elsif en_mult_s = '1' then
                    mult_busy <= '1';
                end if;

                if set_init_ad = '1' then
                    sel_mux1 <= '1';
                elsif clr_init_ad = '1' then
                    sel_mux1 <= '0';
                end if;

                if bdi_rdy = '1' then
                    is_decrypt <= mode;
                end if;
                
                if state = S_INIT then
                    len_a_r <= (others => '0');
                    len_d_r <= (others => '0');
                else
                    if (bdi_rdy = '1' and bdi_valid = '1') then
                        if (bdi_type(2 downto 1) = BDI_TYPE_ASS) then
                            len_a_r <= std_logic_vector(unsigned(len_a_r) 
                                        + unsigned(bdi_size));
                        elsif (bdi_type(2 downto 1) = BDI_TYPE_DAT) then
                            len_d_r <= std_logic_vector(unsigned(len_d_r) 
                                        + unsigned(bdi_size));
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
    len_a <= len_a_r & "000";
    len_d <= len_d_r & "000";

    p_state:
    process( state, bdi_valid, bdi_size, bdi_type, bdi_eot, bdi_eoi, mode,
        aes_busy, mult_busy, key_valid, key_update, mult_done, bdo_ready,
        is_decrypt)
    begin
        --! Default values
        nstate          <= state;
        bdi_rdy         <= '0';
        bdo_vld         <= '0';
        key_ready       <= '0';

        en_key          <= '0';
        en_hashkey      <= '0';
        en_npub         <= '0';
        en_ctr          <= '0';
        en_aes_s        <= '0';
        en_mult_s       <= '0';
        clr_hashkey     <= '0';
        clr_ctr         <= '0';
        clr_mult        <= '0';
        sel_tag         <= '0';
        sel_mux2        <= "00";
        sel_aes         <= '0';
        set_init_ad     <= '0';
        clr_init_ad     <= '0';
        msg_auth_done   <= '0';

        case state is
            when S_INIT =>
                nstate       <= S_KEY_CHECK;
                clr_ctr      <= '1';
                clr_mult     <= '1';
                set_init_ad  <= '1';

            when S_KEY_CHECK =>
                if (key_update = '0' and bdi_valid = '1') then
                    nstate      <= S_WAIT_NPUB;
                elsif (key_update = '1' and key_valid = '1') then
                    nstate      <= S_LDKEY_1;
                end if;

            when S_LDKEY_1 =>
                key_ready <= '1';
                if (key_valid = '1') then
                    nstate <= S_LDKEY_2;
                    en_key <= '1';
                end if;

            when S_LDKEY_2 =>
                key_ready <= '1';
                if (key_valid = '1') then
                    nstate <= S_LDKEY_3;
                    en_key <= '1';
                end if;

            when S_LDKEY_3 =>
                key_ready <= '1';
                if (key_valid = '1') then
                    nstate <= S_LDKEY_4;
                    en_key <= '1';
                end if;

            when S_LDKEY_4 =>
                key_ready <= '1';
                if (key_valid = '1') then
                    nstate <= S_SETUP_H_PRE;
                    en_key <= '1';
                end if;

            when S_SETUP_H_PRE =>
                nstate      <= S_SETUP_H;
                sel_aes     <= '1';
                en_aes_s    <= '1';
                clr_hashkey <= '1';

            when S_SETUP_H =>
                if (aes_busy = '0' and bdi_valid = '1') then
                    nstate       <= S_WAIT_NPUB;
                    en_hashkey   <= '1';
                end if;

            when S_WAIT_NPUB =>
                bdi_rdy <= '1';
                if (bdi_valid = '1') then
                    if (bdi_eoi = '1') then
                        nstate <= S_START_EK0;
                    else
                        nstate <= S_AUTH_WAIT_DATA;
                        en_ctr <= '1';
                    end if;
                    en_npub <= '1';
                end if;

            when S_AUTH_WAIT_DATA =>
                if (mode = '1') then
                    sel_mux2 <= "01";
                end if;
                if (bdi_valid = '1') then
                    if (bdi_type(2 downto 1) = "00" and mult_busy = '0') then
                        --! Prepare the first output of AES+1 for when bdi_eot = '1'
                        if (bdi_eot = '1' and aes_busy = '0') then
                            --! Checking whether there's any more segment
                            if (bdi_eoi = '0') then
                                nstate      <= S_DATA_WAIT_AES;
                                en_mult_s   <= '1';
                                clr_init_ad <= '1';
                                bdi_rdy     <= '1';
                                en_ctr      <= '1';
                                en_aes_s    <= '1';
                            else
                                nstate      <= S_START_EK0;
                                clr_ctr     <= '1';
                                en_mult_s   <= '1';
                                clr_init_ad <= '1';
                                bdi_rdy     <= '1';
                            end if;
                        elsif (bdi_eot = '0') then
                            nstate      <= S_AUTH_WAIT_MULT;
                            en_mult_s   <= '1';
                            bdi_rdy  <= '1';
                        end if;
                    elsif (aes_busy = '0') then
                        --! For the case when there's no AD segment
                        nstate      <= S_DATA_WAIT_AES;
                        clr_init_ad <= '1';
                        en_ctr      <= '1';
                        en_aes_s    <= '1';
                    end if;
                end if;

            when S_AUTH_WAIT_MULT =>
                if (mult_busy = '0' or mult_done = '1') then
                    nstate <= S_AUTH_WAIT_DATA;
                end if;

            when S_DATA_WAIT_AES =>
                if (mode = '1') then
                    sel_mux2 <= "01";
                end if;
                if (bdi_valid = '1' and aes_busy = '0'
                    and mult_busy = '0' and bdo_ready = '1')
                then
                    en_mult_s   <= '1';
                    bdo_vld     <= '1';
                    bdi_rdy     <= '1';
                    if (bdi_eot = '1') then
                        nstate      <= S_START_EK0;
                        clr_ctr     <= '1';
                    else
                        en_aes_s    <= '1';
                        en_ctr      <= '1';
                    end if;
                end if;

            when S_START_EK0 =>
                if (aes_busy = '0') then
                    en_aes_s <= '1';
                    nstate   <= S_MULT_LEN;
                end if;

            when S_MULT_LEN =>
                sel_mux2    <= "10";
                if (mult_busy = '0') then
                    nstate      <= S_TAG_OUT;
                    en_mult_s   <= '1';
                end if;

            when S_TAG_OUT =>
                sel_mux2    <= "11";
                sel_tag     <= '1';
                if (aes_busy = '0' and mult_busy = '0'
                    and ((is_decrypt = '0' and bdo_ready = '1')
                        or (is_decrypt = '1' and bdi_valid = '1')))
                then
                    nstate  <= S_INIT;
                    if (is_decrypt = '1') then
                        bdi_rdy       <= '1';
                        msg_auth_done <= '1';
                    else
                        bdo_vld <= '1';
                    end if;
                end if;

        end case;
    end process;

end behavior;

