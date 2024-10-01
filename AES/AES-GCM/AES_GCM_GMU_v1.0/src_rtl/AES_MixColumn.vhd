-------------------------------------------------------------------------------
--! @file       AES_MixColumn.vhd
--! @brief      A single operation of MixColumns operation
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

entity AES_MixColumn is
    port(
        input       : in  t_AES_column;
        output      : out t_AES_column
    );
end AES_MixColumn;

-------------------------------------------------------------------------------
--! @brief  Architecture definition of AES_MixColumn
-------------------------------------------------------------------------------

architecture structure of AES_MixColumn is
    signal mulx2    : t_AES_column;
    signal mulx3    : t_AES_column;
begin

    m_gen : for i in 0 to 3 generate
        m2  : entity work.AES_mul(AES_mulx02)
            port map (  input  => input(i),
                        output => mulx2(i));
        m3  : entity work.AES_mul(AES_mulx03)
            port map (  input  => input(i),
                        output => mulx3(i));
    end generate;

    output(0) <= mulx2(0) xor mulx3(1) xor input(2) xor input(3);
    output(1) <= input(0) xor mulx2(1) xor mulx3(2) xor input(3);
    output(2) <= input(0) xor input(1) xor mulx2(2) xor mulx3(3);
    output(3) <= mulx3(0) xor input(1) xor input(2) xor mulx2(3);
end structure;