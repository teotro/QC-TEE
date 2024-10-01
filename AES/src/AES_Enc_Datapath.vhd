-------------------------------------------------------------------------------
--! @file       AES_Enc_Datapath.vhd
--! @brief      A datapath module for AES_Enc_Datapath.vhd
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

use work.aes_pkg.all;

entity AES_Enc_Datapath is
    generic (
        G_SBOX_LOGIC    : boolean := False
    );
    port(
        clk         : in  std_logic;
        rst         : in  std_logic;
        din         : in  t_AES_state;
        key         : in  t_AES_state;
        dout        : out t_AES_state;

        sel_fkey    : in  std_logic;
        en_fkey     : in  std_logic;
        en_rkey     : in  std_logic;
        wr_rkey     : in  std_logic;
        round       : in  std_logic_vector(3 downto 0);
        sel_in      : in  std_logic;
        en_in       : in  std_logic);
end AES_Enc_Datapath;

-------------------------------------------------------------------------------
--! @brief  Architecture definition of AES_Enc_Datapath
-------------------------------------------------------------------------------

architecture structure of AES_Enc_Datapath is
    signal from_reg         : t_AES_state;
    signal from_round_fdb   : t_AES_state;
    signal ki_state         : t_AES_state;
    signal ko_state         : t_AES_state;    
    signal fkey             : t_AES_state;
    signal rkey_state       : t_AES_state;
    signal ko_reg           : t_AES_state;

    signal ko               : std_logic_vector(AES_BLOCK_SIZE-1 downto 0);
    signal rkey             : std_logic_vector(AES_BLOCK_SIZE-1 downto 0);
    type t_key_ram is array (0 to 15) of std_logic_vector(AES_BLOCK_SIZE-1 downto 0);
    signal key_ram : t_key_ram;
begin
    u_inv_ko: entity work.AES_invmap(structure)
    port map ( ii => ko_state, 
               oo => ko);
               
    u_map_rkey: entity work.AES_map(structure)
    port map ( ii => rkey, 
               oo => rkey_state);
                              
    p_reg: process(clk)
    begin
        if rising_edge(clk) then
            if en_in = '1' then
                if sel_in = '1' then
                    for i in 0 to 3 loop
                        for j in 0 to 3 loop
                            from_reg(j,i) <= din(j,i) xor fkey(j,i);
                        end loop;
                    end loop;   
                else
                    from_reg <= from_round_fdb;
                end if;
            end if;
            if en_fkey = '1' then
                fkey <= key;
            end if;
            if wr_rkey = '1' then
                key_ram(to_integer(unsigned(round))) <= ko;
                ko_reg                               <= ko_state;
            end if;
            if en_rkey = '1' then
                rkey <= key_ram(to_integer(unsigned(round)));
            end if;
        end if;
    end process;

    u_round: entity work.AES_Round(basic)
    generic map (G_SBOX_LOGIC => G_SBOX_LOGIC)
    port map (
        din         => from_reg,
        rkey        => rkey_state,
        dout_fdb    => from_round_fdb,
        dout        => dout);

    --! Key Expansion
    ki_state <= fkey when sel_fkey = '1' else ko_reg;
    u_keyexp: entity work.AES_KeyUpdate(key_size_128)
    generic map (G_SBOX_LOGIC => G_SBOX_LOGIC)
    port map (
        round       => round,
        ki          => ki_state,
        ko          => ko_state);

end structure;