-------------------------------------------------------------------------------
--! @file       AES_InvMixColumn.vhd
--! @brief      A single InvMixcolumn operation
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

entity AES_InvMixColumn is
    port(
        input       : in  t_AES_column;
        output      : out t_AES_column
    );
end AES_InvMixColumn;

-------------------------------------------------------------------------------
--! @brief  Architecture definition of AES_InvMixColumn
-------------------------------------------------------------------------------

architecture structure of AES_InvMixColumn is
    signal mulx14    : t_AES_column;
    signal mulx13    : t_AES_column;
    signal mulx11    : t_AES_column;
    signal mulx09    : t_AES_column;
begin

    m_gen : for i in 0 to AES_WORD_SIZE/AES_SBOX_SIZE -1 generate
        m14  : entity work.AES_mul(AES_mulx14)
            port map (  input  =>  input(i),
                        output => mulx14(i));
        m13  : entity work.AES_mul(AES_mulx13)
            port map (  input  =>  input(i),
                        output => mulx13(i));
        m11  : entity work.AES_mul(AES_mulx11)
            port map (  input  =>  input(i),
                        output => mulx11(i));
        m09  : entity work.AES_mul(AES_mulx09)
            port map (  input  =>  input(i),
                        output => mulx09(i));
    end generate;

    output(0) <= mulx14(0) xor mulx11(1) xor mulx13(2) xor mulx09(3);
    output(1) <= mulx09(0) xor mulx14(1) xor mulx11(2) xor mulx13(3);
    output(2) <= mulx13(0) xor mulx09(1) xor mulx14(2) xor mulx11(3);
    output(3) <= mulx11(0) xor mulx13(1) xor mulx09(2) xor mulx14(3);
end structure;