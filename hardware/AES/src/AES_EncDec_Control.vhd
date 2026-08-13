-------------------------------------------------------------------------------
--! @file       AES_EncDec_Datapath.vhd
--! @brief      A controller for AES_EncDec.vhd
--! @project    CAESAR Candidate Evaluation
--! @author     Ekawat (ice) Homsirikamol
--! @copyright  Copyright (c) 2014 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, U.S.A.
--!             All rights Reserved.
--! @license    This project is released under the GNU Public License.
--!             The license and distribution terms for this file may be
--!             found in the file LICENSE in this distribution or at
--!             http://www.gnu.org/licenses/gpl-3.0.txt
--! @note       This is publicly available encryption source code that falls
--!             under the License Exception TSU (Technology and software-
--!             —unrestricted)
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.AES_pkg.all;

entity AES_EncDec_Control is
    generic (
        G_RNDS          : integer := AES_ROUNDS;
        G_OBUF          : boolean := False
    );
    port(
        clk             : in  std_logic;
        rst             : in  std_logic;

        --! Internal
        sel_decrypt     : out std_logic;
        invround        : out std_logic_vector(3 downto 0);
        round           : out std_logic_vector(3 downto 0);
        en_rkey         : out std_logic;
        wr_rkey         : out std_logic;
        en_fkey         : out std_logic;
        en_lkey         : out std_logic;
        sel_fkey        : out std_logic;
        sel_round       : out std_logic;
        sel_in          : out std_logic_vector(1 downto 0);
        en_in           : out std_logic;

        --! External
        init            : in  std_logic;
        done_init       : out std_logic;
        start           : in  std_logic;
        decrypt         : in  std_logic;
        ready           : out std_logic;
        almost_done     : out std_logic;
        done            : out std_logic);
end AES_EncDec_Control;

-------------------------------------------------------------------------------
--! @brief  Architecture definition of AES_EncDec_Control
-------------------------------------------------------------------------------

architecture behav of AES_EncDec_Control is
    --! Internal Registers
    type t_state is (S_RESET, S_WAIT_START, S_INIT_KEY, S_PROCESS);
    signal state            : t_state;
    signal state_next       : t_state;
    signal round_r          : std_logic_vector(3 downto 0);
    signal round_next       : std_logic_vector(3 downto 0);
    signal invround_r       : std_logic_vector(3 downto 0);
    signal invround_next    : std_logic_vector(3 downto 0);
    signal decrypt_r        : std_logic;
    signal almost_done_r    : std_logic;
    signal done_r           : std_logic;
    signal done_init_r      : std_logic;

    --! Internal signals
    signal en_decrypt_s     : std_logic;
    signal almost_done_s    : std_logic;
    signal done_init_s      : std_logic;
begin
    p_fsm: process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                state <= S_RESET;
            else
                state       <= state_next;
            end if;

            if (en_decrypt_s = '1') then
                decrypt_r  <= decrypt;
            end if;
            round_r       <= round_next;
            invround_r    <= invround_next;
            done_init_r   <= done_init_s;
            almost_done_r <= almost_done_s;
            done_r        <= almost_done_r;
        end if;
    end process;
    round          <= round_r;
    invround       <= invround_r;
    sel_decrypt    <= decrypt_r;
    done_init      <= done_init_r;

    gobuf:
    if not G_OBUF generate
        almost_done    <= almost_done_r;
        done           <= done_r;
    end generate;
    gnobuf:
    if G_OBUF generate
        process(clk)
        begin
            if rising_edge(clk) then
                almost_done    <= almost_done_r;
                done           <= done_r;
            end if;
        end process;
    end generate;

    p_comb: process(state, round_r, init, start, decrypt_r, decrypt, invround_r)
    begin
        --! Default values
        state_next 	   <= state;
        round_next 	   <= round_r;        
        ready          <= '0';
        en_lkey        <= '0';
        en_fkey        <= '0';
        wr_rkey        <= '0';
        sel_fkey       <= '0';
        sel_in         <= "00";
        en_in          <= '0';
        sel_round      <= '0';
        en_rkey        <= '0';        
        en_decrypt_s   <= '0';
        almost_done_s  <= '0';
        done_init_s    <= '0';
        invround_next   <= std_logic_vector(to_unsigned(G_RNDS-1,4));
        
        case state is
            when S_RESET =>
                round_next      <= std_logic_vector(to_unsigned(1,4));
                invround_next   <= std_logic_vector(to_unsigned(G_RNDS-1,4));
                state_next      <= S_WAIT_START;

            when S_WAIT_START =>
                ready <= '1';
                if (init = '1') then
                    round_next  <= (others => '0');
                    en_lkey     <= '1';
                    en_fkey     <= '1';
                    state_next  <= S_INIT_KEY;
                elsif (start = '1') then
                    en_decrypt_s    <= '1';
                    sel_in          <= "10";
                    en_in           <= '1';
                    en_rkey         <= '1';
                    if (decrypt = '1') then
                        sel_round <= '1';
                    else
                        sel_fkey  <= '1';
                    end if;                    
                    round_next      <= round_r + 1;
                    invround_next   <= invround_r - 1;
                    state_next      <= S_PROCESS;
                end if;

            when S_INIT_KEY =>
                wr_rkey     <= '1';
                if (round_r = 0) then
                        sel_fkey <= '1';
                end if;
                if (round_r = G_RNDS) then
                    round_next  <= std_logic_vector(to_unsigned(1,4));
                    done_init_s <= '1';
                    state_next  <= S_WAIT_START;
                else
                    round_next  <= round_r + 1;
                    en_lkey     <= '1';
                end if;

            when S_PROCESS =>
                en_rkey  <= '1';
                en_in    <= '1';
                if (decrypt_r = '1') then
                    sel_round <= '1';
                    sel_in    <= "01";
                end if;
                if (round_r = G_RNDS) then
                    round_next      <= std_logic_vector(to_unsigned(1,4));
                    invround_next   <= std_logic_vector(to_unsigned(G_RNDS-1,4));                    
                    state_next      <= S_WAIT_START;
                else
                    round_next      <= round_r + 1;
                    invround_next   <= invround_r - 1;
                end if;
                if (round_r = G_RNDS-1) then
                    almost_done_s   <= '1';
                end if;
                
        end case;
    end process;
end behav;