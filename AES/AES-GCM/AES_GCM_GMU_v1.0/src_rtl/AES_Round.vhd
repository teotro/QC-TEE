-------------------------------------------------------------------------------
--! @file       AES_Round.vhd
--! @brief      AES Round
--! @project    CAESAR Candidate Evaluation
--! @author     Marcin Rogawski   
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

entity AES_Round is
    generic (
        G_SBOX_LOGIC    : boolean := False
    );
    port(
        din 		: in  t_AES_state;
        rkey        : in  t_AES_state;
        dout_fdb 	: out t_AES_state;
        dout		: out t_AES_state
    );
end AES_Round;

-------------------------------------------------------------------------------
--! @brief  Architecture definition of AES_Sbox
-------------------------------------------------------------------------------

architecture basic of AES_Round is
    signal	after_subbytes		: t_AES_state;
    signal	after_shiftrows		: t_AES_state;
    signal	after_mixcolumns	: t_AES_state;
begin

    --! SubBytes
    sb	: entity work.AES_SubBytes(basic)	
        generic map (G_SBOX_LOGIC => G_SBOX_LOGIC)
        port map (input=>din,               output=>after_subbytes);

    --! ShiftRows
    sr	: entity work.AES_ShiftRows(basic)	
        port map (input=>after_subbytes,    output=>after_shiftrows);

    --! MixColumns
    mc	: entity work.AES_MixColumns(basic)	
        port map (input=>after_shiftrows,   output=>after_mixcolumns);

    --! AddRoundKey
    gAddRoundKeyRow: for i in 0 to 3 generate
        gAddRoundKeyCol: for j in 0 to 3 generate
            dout_fdb(j,i) <= after_mixcolumns(j,i) xor rkey(j,i);
            dout(j,i)     <= after_shiftrows(j,i)  xor rkey(j,i);
        end generate;
    end generate;

end basic;