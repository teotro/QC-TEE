-------------------------------------------------------------------------------
--! @file       AES_InvRound.vhd
--! @brief      An InvRound used by AES decryption operation
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

entity AES_InvRound is
    generic (
        G_SBOX_LOGIC    : boolean := False
    );
    port( 
        din 		: in  t_AES_state;
        rkey        : in  t_AES_state;
        dout_fdb 	: out t_AES_state;
        dout		: out t_AES_state
    );
end AES_InvRound;

-------------------------------------------------------------------------------
--! @brief  Architecture definition of AES_InvRound
-------------------------------------------------------------------------------

architecture basic of AES_InvRound is
    signal	after_invsubbytes		: t_AES_state;
    signal	after_invshiftrows		: t_AES_state;
    signal	after_addroundkey		: t_AES_state;
begin

    --! ShiftRows 	
    sr	: entity work.AES_InvShiftRows(basic)	        
        port map (input=>din,                output=>after_invshiftrows);
    
    --! SubBytes
    sb	: entity work.AES_InvSubBytes(basic)	
        generic map (G_SBOX_LOGIC => G_SBOX_LOGIC)
        port map (input=>after_invshiftrows, output=>after_invsubbytes);

    --! AddRoundKey
    gAddRoundKeyRow: for i in 0 to 3 generate
        gAddRoundKeyCol: for j in 0 to 3 generate
            after_addroundkey(j,i) <= after_invsubbytes(j,i) xor rkey(j,i);
        end generate;
    end generate;
    
    dout              <= after_addroundkey;

    -- MixColumns
    mc	: entity work.AES_InvMixColumns(basic)	
        port map (input=>after_addroundkey, output=>dout_fdb);
end basic; 