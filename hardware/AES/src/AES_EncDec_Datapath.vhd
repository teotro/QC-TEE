-------------------------------------------------------------------------------
--! @file       AES_EncDec_Datapath.vhd
--! @brief      A datapath module for AES_EncDec.vhd
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

entity AES_EncDec_Datapath is
    generic (
        G_SBOX_LOGIC    : boolean := False
    );
    port(
        clk             : in  std_logic;
        rst             : in  std_logic;
        din             : in  t_AES_state;
        key             : in  t_AES_state;
        dout            : out t_AES_state;

        --! Control Signals
        sel_decrypt     : in  std_logic;
        invround        : in  std_logic_vector(3 downto 0);
        round           : in  std_logic_vector(3 downto 0);
        en_rkey         : in  std_logic;
        wr_rkey         : in  std_logic;
        en_lkey         : in  std_logic;
        en_fkey         : in  std_logic;
        sel_fkey        : in  std_logic;
        sel_round       : in  std_logic;
        sel_in          : in  std_logic_vector(1 downto 0);
        en_in           : in  std_logic);
end AES_EncDec_Datapath;

-------------------------------------------------------------------------------
--! @brief  Architecture definition of AES_EncDec_Datapath
-------------------------------------------------------------------------------

architecture structure of AES_EncDec_Datapath is
    signal from_reg             : t_AES_state;
    signal from_round_fdb       : t_AES_state;
    signal from_invround_fdb    : t_AES_state;
    signal round_dout           : t_AES_state;
    signal invround_dout        : t_AES_state;
    signal ki_state             : t_AES_state;
    signal ko_state             : t_AES_state;
    signal rkey_state           : t_AES_state;
    signal round_sel            : std_logic_vector(3 downto 0);

    signal lkey_reg             : t_AES_state;
    signal fkey_reg             : t_AES_state;

    signal ki                   : std_logic_vector(AES_BLOCK_SIZE-1 downto 0);
    signal rkey                 : std_logic_vector(AES_BLOCK_SIZE-1 downto 0);
    type t_key_ram is array (0 to 15) of 
        std_logic_vector(AES_BLOCK_SIZE-1 downto 0);
    signal key_ram : t_key_ram;
begin
    u_inv_ki: entity work.AES_invmap(structure)
    port map ( ii => ki_state,
               oo => ki);

    u_map_rkey: entity work.AES_map(structure)
    port map ( ii => rkey,
               oo => rkey_state);

    p_reg: process(clk)
    begin
        if rising_edge(clk) then
            --! Input Register
            if en_in = '1' then
                if sel_in = "00" then
                    from_reg <= from_round_fdb;
                elsif sel_in = "01" then
                    from_reg <= from_invround_fdb;
                else
                    for i in 0 to 3 loop
                        for j in 0 to 3 loop
                            from_reg(j,i) <= din(j,i) xor ki_state(j,i);
                        end loop;
                    end loop;
                end if;
            end if;

            --! Round Key Ram
            if wr_rkey = '1' then
                key_ram(to_integer(unsigned(round_sel))) <= ki;
            end if;
            if en_rkey = '1' then
                rkey <= key_ram(to_integer(unsigned(round_sel)));
            end if;

            --! Key Register
            if en_lkey = '1' then
                lkey_reg <= ko_state;
            end if;
            if en_fkey = '1' then
                fkey_reg <= key;
            end if;
        end if;
    end process;
    round_sel <= invround when sel_round = '1' else round;

    u_round: entity work.AES_Combined_Round(structure)
    generic map (G_SBOX_LOGIC => G_SBOX_LOGIC)
    port map (
        din             => from_reg,
        rkey            => rkey_state,
        sel_decrypt     => sel_decrypt,
        dout_enc_fdb    => from_round_fdb,
        dout_dec_fdb    => from_invround_fdb,
        dout            => dout);

    --! Key Expansion
    ki_state    <= fkey_reg  when sel_fkey = '1' else lkey_reg;
    u_keyexp: entity work.AES_KeyUpdate(key_size_128)
    generic map (G_SBOX_LOGIC => G_SBOX_LOGIC)
    port map (
        round       => round,
        ki          => ki_state,
        ko          => ko_state);

end structure;