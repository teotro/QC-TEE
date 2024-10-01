-------------------------------------------------------------------------------
--! @file       AES_Enc_KOF_Control.vhd
--! @brief      A controller for AES_EncDec_KOF.vhd
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

use work.aes_pkg.all;

entity AES_Enc_KOF_Control is
    generic (
        G_RNDS      : integer := AES_ROUNDS);
    port(
        clk         : in  std_logic;
        rst         : in  std_logic;
        start       : in  std_logic;

        round       : out std_logic_vector(3 downto 0);
        sel_in      : out std_logic;
        en_in       : out std_logic;
        ready       : out std_logic;
        done        : out std_logic);
end AES_Enc_KOF_Control;

-------------------------------------------------------------------------------
--! @brief  Architecture definition of AES_Enc_KOF_Control
-------------------------------------------------------------------------------

architecture behav of AES_Enc_KOF_Control is
    type t_state is (S_RESET, S_WAIT_START, S_PROCESS, S_DONE);
    signal state        : t_state;
    signal state_next   : t_state;
    signal round_r      : std_logic_vector(3 downto 0);
    signal round_next   : std_logic_vector(3 downto 0);
begin

    p_fsm: process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                state <= S_RESET;
            else
                state <= state_next;
            end if;
            round_r <= round_next;
        end if;
    end process;
    round <= round_r;

    p_comb: process(state, round_r, start)
    begin
        --! Default values
        state_next  <= state;
        round_next  <= round_r;        
        sel_in  <= '0';
        en_in   <= '0';
        ready   <= '0';
        done    <= '0';

        case state is
            when S_RESET =>
                round_next <= (others => '0');
                state_next <= S_WAIT_START;

            when S_WAIT_START =>
                ready <= '1';
                if (start = '1') then
                    sel_in <= '1';
                    en_in  <= '1';
                    round_next <= round_r + 1;
                    state_next <= S_PROCESS;
                end if;

            when S_PROCESS =>
                en_in <= '1';
                if (round_r = G_RNDS-1) then
                    round_next <= (others => '0');
                    state_next <= S_DONE;
                else
                    round_next <= round_r + 1;
                end if;

            when S_DONE =>
                done  <= '1';
                ready <= '1';
                if (start = '1') then
                    sel_in <= '1';
                    en_in  <= '1';
                    round_next <= round_r + 1;
                    state_next <= S_PROCESS;
                else
                    state_next <= S_WAIT_START;
                end if;
        end case;
    end process;

end behav;