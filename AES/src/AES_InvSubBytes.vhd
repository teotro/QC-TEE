-------------------------------------------------------------------------------
--! @file       AES_InvSubBytes.vhd
--! @brief      A straightforward implementation of AES InvSubBytes operation
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

use work.AES_pkg.all;

entity AES_InvSubBytes is
    generic (
        G_SBOX_LOGIC : boolean := False
    );
    port(
        input       : in  t_AES_state;
        output      : out t_AES_state
    );
end AES_InvSubBytes;

-------------------------------------------------------------------------------
--! @brief  Architecture definition of AES_InvSubBytes
-------------------------------------------------------------------------------

architecture basic of AES_InvSubBytes is
begin
    gRow: for i in 0 to 3 generate
        gCol: for j in 0 to 3 generate
            gnlogic:
            if (not G_SBOX_LOGIC) generate
                sbox: entity work.AES_InvSbox(distributed_rom)
                    port map ( input  =>  input(j,i),
                               output => output(j,i));
            end generate;
            glogic:
            if (G_SBOX_LOGIC) generate
                sbox: entity work.AES_InvSbox(logic)
                    port map ( input  =>  input(j,i),
                               output => output(j,i));
            end generate;
        end generate;
    end generate;
end basic;