-------------------------------------------------------------------------------
--! @file       AES_Enc_KOF.vhd
--! @brief      A top-level module of an AES encryption unit.
--!             Calculation of round key is performed on the fly.
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
use ieee.numeric_std.all;

use work.AES_pkg.all;

entity AES_Enc_KOF is
    generic (
        G_RNDS          : integer := AES_ROUNDS;
        G_SBOX_LOGIC    : boolean := False;
        G_OBUF          : boolean := False
    );
    port(
        clk         : in  std_logic;
        rst         : in  std_logic;
        din         : in  std_logic_vector(AES_BLOCK_SIZE-1 downto 0);
        key         : in  std_logic_vector(AES_BLOCK_SIZE-1 downto 0);
        dout        : out std_logic_vector(AES_BLOCK_SIZE-1 downto 0);

        start       : in  std_logic;
        ready       : out std_logic;
        done        : out std_logic
    );
end AES_Enc_KOF;

-------------------------------------------------------------------------------
--! @brief  Architecture definition of AES_Enc_KOF
-------------------------------------------------------------------------------

architecture structure of AES_Enc_KOF is
    signal sel_in       : std_logic;
    signal en_in        : std_logic;
    signal round        : std_logic_vector(3 downto 0);
    signal done_s       : std_logic;
    signal dout_s       : std_logic_vector(127 downto 0);

    signal key_state    : t_AES_state;
    signal din_state    : t_AES_state;
    signal dout_state   : t_AES_state;
begin
    u_map_key: entity work.AES_map(structure)
    port map ( ii => key,
               oo => key_state);

    u_map_din: entity work.AES_map(structure)
    port map ( ii => din,
               oo => din_state);

    u_invmap: entity work.AES_invmap(structure)
    port map ( ii => dout_state,
               oo => dout_s);

    gnobuf:
    if (not G_OBUF) generate
        dout <= dout_s;
        done <= done_s;
    end generate;
    gobuf:
    if (G_OBUF) generate
        process(clk)
        begin
            if rising_edge(clk) then
                if done_s = '1' then
                    dout <= dout_s;
                end if;
                done <= done_s;
            end if;
        end process;
    end generate;

    u_dp: entity work.AES_Enc_KOF_Datapath(structure)
    generic map (G_SBOX_LOGIC => G_SBOX_LOGIC)
    port map (  clk         => clk,
                rst         => rst,
                --! Data
                din         => din_state,
                key         => key_state,
                dout        => dout_state,
                --! Control
                round       => round,
                sel_in      => sel_in,
                en_in       => en_in);

    u_ctrl: entity work.AES_Enc_KOF_Control(behav)
    generic map (
                G_RNDS      => G_RNDS
    )
    port map (  clk         => clk,
                rst         => rst,
                --! External
                start       => start,
                ready       => ready,
                done        => done_s,
                --! Internal
                round       => round,
                sel_in      => sel_in,
                en_in       => en_in);

end structure;