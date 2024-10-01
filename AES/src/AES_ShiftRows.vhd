-------------------------------------------------------------------------------
--! @file       AES_ShiftRows.vhd
--! @brief      A Straightforward implementation of AES ShiftRows operation.
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
use ieee.std_logic_unsigned.all;

use work.AES_pkg.all;

entity AES_ShiftRows is
    port(
        input 		: in  t_AES_state;
        output 		: out t_AES_state
    );
end AES_ShiftRows;

-------------------------------------------------------------------------------
--! @brief  Architecture definition of AES_ShiftRows
-------------------------------------------------------------------------------

architecture basic of AES_ShiftRows is
begin
    gRow: for i in 0 to 3 generate
        gCol: for j in 0 to 3 generate
            output(j,i) <= input(j,(i+j) mod 4);
        end generate;
    end generate;
end basic;