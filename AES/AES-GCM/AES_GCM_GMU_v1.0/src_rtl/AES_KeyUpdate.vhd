-------------------------------------------------------------------------------
--! @file       AES_KeyUpdate.vhd
--! @brief      A key update function used for KeyScheduling of AES.
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

entity AES_KeyUpdate is
    generic (
        G_SBOX_LOGIC    : boolean := False
    );
    port (
        round   : in  std_logic_vector(3 downto 0);
        ki      : in  t_AES_state;
        ko      : out t_AES_state
    );
end AES_KeyUpdate;

-------------------------------------------------------------------------------
--! @brief  Architecture definition of AES_KeyUpdate
-------------------------------------------------------------------------------

architecture key_size_128 of AES_KeyUpdate is
    type rcon_type is array (0 to 15) of std_logic_vector(AES_SBOX_SIZE-1 downto 0);
    constant rcon : rcon_type :=
		( X"01", X"02", X"04", X"08", X"10", X"20", X"40", X"80",
          X"1b", X"36", X"6c", X"d8", X"ab", X"4d", X"9a", X"00"
		 );

    signal after_rotword	:   t_AES_column;
    signal after_subword	:   t_AES_column;
    signal after_rcon		:   t_AES_column;
    signal word             :   t_AES_state;
begin
    gAfterRot: for j in 0 to 3 generate
        after_rotword(j) <= ki((j+1) mod 4,3);
    end generate;

    gAfterSub: for j in 0 to 3 generate
        gdist: if (not G_SBOX_LOGIC) generate
            sbox: entity work.AES_Sbox(distributed_rom)
            port map (
                input   =>  after_rotword(j),
                output  =>  after_subword(j)
            );
        end generate;
        glogic: if (G_SBOX_LOGIC) generate
            sbox: entity work.AES_Sbox(logic)
            port map (
                input   =>  after_rotword(j),
                output  =>  after_subword(j)
            );        
        end generate;
	end generate;

    after_rcon(0) <= after_subword(0) xor rcon(to_integer(unsigned(round)));
    gAfterRcon: for j in 1 to 3 generate
        after_rcon(j) <= after_subword(j);
	end generate;

    --! Cascading XOR
    gXorCol0: for j in 0 to 3 generate
        word(j,0) <= ki(j,0) xor after_rcon(j);
    end generate;

    gXorRow: for i in 1 to 3 generate
        gXorCol: for j in 0 to 3 generate
            word(j,i) <= ki(j,i) xor word(j,i-1);
        end generate;
    end generate;

    --! Output
    ko <= word;
end key_size_128;