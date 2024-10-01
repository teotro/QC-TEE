-------------------------------------------------------------------------------
--! @file       AES_Combined_Round.vhd
--! @brief      Combined AES round and inversed round.
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

entity AES_Combined_Round is
    generic (
        G_SBOX_LOGIC    : boolean := False
    );
    port(
        din             : in  t_AES_state;
        rkey            : in  t_AES_state;
        sel_decrypt     : in  std_logic;
        dout_enc_fdb    : out t_AES_state;
        dout_dec_fdb    : out t_AES_state;
        dout            : out t_AES_state
    );
end AES_Combined_Round;

-------------------------------------------------------------------------------
--! @brief  Architecture definition of AES_Combined_Round
-------------------------------------------------------------------------------

architecture structure of AES_Combined_Round is
    signal after_mul_invx       : t_AES_state;
    signal after_inv_affine     : t_AES_state;
    signal after_mul_invmx      : t_AES_state;
    signal to_invgf8            : t_AES_state;
    signal after_invgf8         : t_AES_state;
    signal after_subbytes       : t_AES_state;
    signal after_invsubbytes    : t_AES_state;    
    signal after_shiftrows      : t_AES_state;
    signal after_mixcolumns     : t_AES_state;    
    signal after_invshiftrows   : t_AES_state;
    signal after_addroundkey    : t_AES_state;
    signal dout_dec             : t_AES_state;
    signal dout_enc             : t_AES_state;
begin
    --! SubBytes
    glogic:
    if (not G_SBOX_LOGIC) generate        
        sb	: entity work.AES_SubBytes(basic)	
            generic map (G_SBOX_LOGIC => G_SBOX_LOGIC)
            port map (input=>din,               output=>after_subbytes);
        invsb	: entity work.AES_InvSubBytes(basic)	
            generic map (G_SBOX_LOGIC => G_SBOX_LOGIC)
            port map (input=>din, output=>after_invsubbytes);
    end generate;
    gnlogic:
    if (G_SBOX_LOGIC) generate
        gSubRow: for i in 0 to 3 generate
            gSubCol: for j in 0 to 3 generate
                --! Enc
                after_mul_invx(j,i)     <= MUL_INVX(din(j,i));
                --! Dec
                after_inv_affine(j,i)   <= din(j,i) xor AFFINE_C;
                after_mul_invmx(j,i)    <= MUL_INVMX(after_inv_affine(j,i));
                --! Shared
                to_invgf8(j,i)          <= after_mul_invmx(j,i)
                                            when sel_decrypt = '1'
                                            else after_mul_invx(j,i);
                after_invgf8(j,i)       <= GF_INV_GF8(to_invgf8(j,i));
                --! Enc
                after_subbytes(j,i)     <= MUL_MX(after_invgf8(j,i)) xor AFFINE_C;
                --! Dec
                after_invsubbytes(j,i)  <= MUL_X(after_invgf8(j,i));
            end generate;
        end generate;
    end generate;

    --! == Round
    --! ShiftRows
    sr: entity work.AES_ShiftRows(basic)
    port map (
        input   => after_subbytes,    
        output  => after_shiftrows
    );

    --! MixColumns
    mc: entity work.AES_MixColumns(basic)
    port map (
        input   => after_shiftrows,   
        output  => after_mixcolumns
    );

    --! AddRoundKey
    gAddRowEnc: for i in 0 to 3 generate
        gAddColEnc: for j in 0 to 3 generate
            dout_enc_fdb(j,i) <= after_mixcolumns(j,i) xor rkey(j,i);
            dout_enc(j,i)     <= after_shiftrows(j,i)  xor rkey(j,i);
        end generate;
    end generate;

    --! == InvRound
    --! InvShiftRows
    invsr: entity work.AES_InvShiftRows(basic)
    port map (
        input   => after_invsubbytes, 
        output  => after_invshiftrows
    );

    --! AddRoundKey
    gAddRowDec: for i in 0 to 3 generate
        gAddColDec: for j in 0 to 3 generate
            after_addroundkey(j,i) <= after_invshiftrows(j,i) xor rkey(j,i);
        end generate;
    end generate;
    dout_dec <= after_addroundkey;

    --! InvMixColumns
    invmc: entity work.AES_InvMixColumns(basic)
    port map (
        input   => after_addroundkey, 
        output  => dout_dec_fdb
    );

    --! == Output
    dout <= dout_dec when sel_decrypt = '1' else dout_enc;
end architecture structure;