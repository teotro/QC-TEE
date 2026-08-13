-------------------------------------------------------------------------------
--! @file       AES_MixColumns.vhd
--! @brief      Straightforward implementation of AES MixColumns operation.
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

entity AES_MixColumns is
    port(
        input       : in  t_AES_state;
        output      : out t_AES_state
    );
end AES_MixColumns;

-------------------------------------------------------------------------------
--! @brief  Architecture definition of AES_MixColumns
-------------------------------------------------------------------------------

architecture basic of AES_MixColumns is
    type t_col_array is array (0 to 3) of t_AES_column;
    signal mc_in    : t_col_array;
    signal mc_out   : t_col_array;
begin
    gRow: for i in 0 to 3 generate
        gCol: for j in 0 to 3 generate
            mc_in(i)(j) <= input(j,i);
            output(j,i) <= mc_out(i)(j);
        end generate;

        mc: entity work.AES_MixColumn(structure)
            port map ( input  =>  mc_in(i),
                       output => mc_out(i));
    end generate;
end basic;