-------------------------------------------------------------------------------
--! @file       AES_pkg.vhd
--! @brief      Package definition used by various AES modules
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

package AES_pkg is
	--! AES constants
	constant AES_SBOX_SIZE				: integer :=  8;
	constant AES_WORD_SIZE				: integer := 32;
	constant AES_BLOCK_SIZE				: integer :=128;
	constant AES_KEY_SIZE				: integer :=128;
    constant AES_ROUNDS                 : integer := 10;

    type t_AES_state     is array (0 to 3, 0 to 3) of std_logic_vector( 7 downto 0);
    type t_AES_column    is array (0 to 3)         of std_logic_vector( 7 downto 0);

    --!========================================================================
    --! Galois field multiplication functions for SBOX
    --! See: Chapter 10.6.1.3 of Cryptographic Engineering
    --!
    --! Gaj K., Chodowiec P. (2009) FPGA and ASIC implementations of the AES.
    --! In: Koc C. (Ed.) Cryptographic engineering. Springer, Berlin, pp 235–294
    --!========================================================================
    constant AFFINE_C           : std_logic_vector(7 downto 0) := x"63";

    function MUL_MX       (x     : std_logic_vector(7 downto 0)) return std_logic_vector;
    function MUL_INVMX    (x     : std_logic_vector(7 downto 0)) return std_logic_vector;
    function MUL_X        (x     : std_logic_vector(7 downto 0)) return std_logic_vector;
	function MUL_INVX     (x     : std_logic_vector(7 downto 0)) return std_logic_vector;
    function GF_INV_GF8   (x     : std_logic_vector(7 downto 0)) return std_logic_vector;

	function GF_SQ_SCL_2  (x     : std_logic_vector(1 downto 0)) return std_logic_vector;
	function GF_SCL_2     (x     : std_logic_vector(1 downto 0)) return std_logic_vector;
	function GF_MUL_2     (x, y  : std_logic_vector(1 downto 0)) return std_logic_vector;
	function GF_MUL_SCL_2 (x, y  : std_logic_vector(1 downto 0)) return std_logic_vector;
	function GF_INV_2     (x     : std_logic_vector(1 downto 0)) return std_logic_vector;
	function GF_SQ_2      (x     : std_logic_vector(1 downto 0)) return std_logic_vector;
	function GF_INV_4     (x     : std_logic_vector(3 downto 0)) return std_logic_vector;
	function GF_MUL_4     (x, y  : std_logic_vector(3 downto 0)) return std_logic_vector;
	function GF_SQ_SCL_4  (x     : std_logic_vector(3 downto 0)) return std_logic_vector;
end AES_pkg;

package body AES_pkg is
    function MUL_MX(x:  std_logic_vector(7 downto 0)) return std_logic_vector is
		variable y : std_logic_vector(7 downto 0);
	begin
		y(7) := x(5) xor x(3);
		y(6) := x(7) xor x(3);
		y(5) := x(6) xor x(0);
		y(4) := x(7) xor x(5) xor x(3);
		y(3) := x(7) xor x(6) xor x(5) xor x(4) xor x(3);
		y(2) := x(6) xor x(5) xor x(3) xor x(2) xor x(0);
		y(1) := x(5) xor x(4) xor x(1);
		y(0) := x(6) xor x(4) xor x(1);
	return y;
	end MUL_MX;

    function MUL_INVMX(x:  std_logic_vector(7 downto 0)) return std_logic_vector is
		variable y : std_logic_vector(7 downto 0);
	begin
		y(7) := x(7) xor x(4);
		y(6) := x(6) xor x(4) xor x(1) xor x(0);
		y(5) := x(6) xor x(4);
		y(4) := x(6) xor x(3) xor x(1) xor x(0);
		y(3) := x(7) xor x(6) xor x(4);
		y(2) := x(7) xor x(5) xor x(2);
		y(1) := x(4) xor x(3) xor x(0);
		y(0) := x(6) xor x(5) xor x(4) xor x(1) xor x(0);
	return y;
	end MUL_INVMX;

    function MUL_X(x:  std_logic_vector(7 downto 0)) return std_logic_vector is
		variable y : std_logic_vector(7 downto 0);
	begin
		y(7) := x(4) xor x(1);
		y(6) := x(7) xor x(6) xor x(5) xor x(3) xor x(1) xor x(0);
		y(5) := x(7) xor x(6) xor x(5) xor x(3) xor x(2) xor x(0);
		y(4) := x(6) xor x(1);
		y(3) := x(6) xor x(5) xor x(4) xor x(3) xor x(2) xor x(1);
		y(2) := x(7) xor x(5) xor x(4) xor x(1);
		y(1) := x(5) xor x(1);
		y(0) := x(2);
		return y;
	end MUL_X;

	function MUL_INVX(x:  std_logic_vector(7 downto 0)) return std_logic_vector is
		variable y : std_logic_vector(7 downto 0);
	begin
		y(7) := x(7) xor x(6) xor x(5) xor x(2) xor x(1) xor x(0);
		y(6) := x(6) xor x(5) xor x(4) xor x(0);
		y(5) := x(6) xor x(5) xor x(1) xor x(0);
		y(4) := x(7) xor x(6) xor x(5) xor x(0);
		y(3) := x(7) xor x(4) xor x(3) xor x(1) xor x(0);
		y(2) := x(0);
		y(1) := x(6) xor x(5) xor x(0);
		y(0) := x(6) xor x(3) xor x(2) xor x(1) xor x(0);
		return y;
	end MUL_INVX;

	function GF_INV_GF8(x:  std_logic_vector(7 downto 0)) return std_logic_vector is
		variable y : std_logic_vector(7 downto 0);
		variable r0, r1, SQ_IN, SQ_OUT, MUL_1_OUT, GF_INV_IN, GF_INV_OUT, MUL_2_OUT , MUL_3_OUT :std_logic_vector(3 downto 0);
	begin
		r1         := x(7 downto 4);
		r0         := x(3 downto 0);
		SQ_IN      := r1 xor r0;
		SQ_OUT     := GF_SQ_SCL_4(x => SQ_IN);
		MUL_1_OUT  := GF_MUL_4(x => r1, y => r0);
		GF_INV_IN  := MUL_1_OUT xor SQ_OUT;
		GF_INV_OUT := GF_INV_4(x => GF_INV_IN);
		MUL_2_OUT  := GF_MUL_4(x => r1, y => GF_INV_OUT);
		MUL_3_OUT  := GF_MUL_4(x => GF_INV_OUT, y => r0);
		y          := MUL_3_OUT  & MUL_2_OUT;
		return y;
	end GF_INV_GF8;

	function GF_SQ_SCL_2 (x: std_logic_vector(1 downto 0)) return std_logic_vector is
		variable y : std_logic_vector(1 downto 0);
	begin
		y := x(1) & (x(1) xor x(0));
		return y;
	end GF_SQ_SCL_2;

	function GF_SCL_2(x:  std_logic_vector(1 downto 0)) return std_logic_vector is
		variable y : std_logic_vector(1 downto 0);
	begin
		y := x(0) & (x(1) xor x(0));
		return y;
	end GF_SCL_2;

	function GF_MUL_2(x,y :  std_logic_vector(1 downto 0)) return std_logic_vector is
		variable o : std_logic_vector(1 downto 0);
	begin
		o(1) :=(((x(1) xor x(0)) and (y(1) xor y(0))) xor (x(1) and y(1)));
        o(0) :=(((x(1) xor x(0)) and (y(1) xor y(0))) xor (x(0) and y(0)));
		return o;
	end GF_MUL_2;


	function GF_MUL_SCL_2(x,y :  std_logic_vector(1 downto 0)) return std_logic_vector is
		variable o : std_logic_vector(1 downto 0);
	begin
		o :=( ((x(1) xor x(0)) and (y(1) xor y(0))) xor (x(0) and y(0))) & ( (x(1) and y(1)) xor (x(0) and y(0)));
		return o;
	end GF_MUL_SCL_2;


	function GF_INV_2(x:  std_logic_vector(1 downto 0)) return std_logic_vector is
		variable y : std_logic_vector(1 downto 0);
	begin
		y(1) := x(0);
	  	y(0) := x(1);
		return y;
	end GF_INV_2;


	function GF_SQ_2(x:  std_logic_vector(1 downto 0)) return std_logic_vector is
		variable y : std_logic_vector(1 downto 0);
	begin
	  	y(1) := x(0);
	  	y(0) := x(1);
		return y;
	end GF_SQ_2;

	function GF_INV_4(x:  std_logic_vector(3 downto 0)) return std_logic_vector is
		variable y : std_logic_vector(3 downto 0);
		variable r0, r1, SQ_IN, SQ_OUT, MUL_1_OUT, GF_INV_IN, GF_INV_OUT, MUL_2_OUT , MUL_3_OUT :std_logic_vector(1 downto 0);
	begin
		r1         := x(3 downto 2);
		r0         := x(1 downto 0);
		SQ_IN      := r1 xor r0;
		SQ_OUT     := GF_SQ_SCL_2(x => SQ_IN);
		MUL_1_OUT  := GF_MUL_2(x => r1, y => r0);
		GF_INV_IN  := MUL_1_OUT xor SQ_OUT;
		GF_INV_OUT := GF_INV_2(x => GF_INV_IN);
		MUL_2_OUT  := GF_MUL_2(x => r1, y => GF_INV_OUT);
		MUL_3_OUT  := GF_MUL_2(x => GF_INV_OUT, y => r0);
		y          := MUL_3_OUT & MUL_2_OUT;
		return y;
	end GF_INV_4;


	function GF_MUL_4(x,y :  std_logic_vector(3 downto 0)) return std_logic_vector is
		variable o : std_logic_vector(3 downto 0);
		variable tao1, tao0, delta1, delta0, fi1, fi0, tmp1, tmp0, RES_MUL1, RES_MUL0,RES_MUL_SCL: std_logic_vector(1 downto 0);
	begin
		tao1        := x(3 downto 2);
		tao0        := x(1 downto 0);
		delta1      := y(3 downto 2);
		delta0      := y(1 downto 0);
		tmp1        := tao1 xor tao0;
		tmp0        := delta1 xor delta0;
		RES_MUL1    := GF_MUL_2(x => tao1, y=> delta1);
		RES_MUL0    := GF_MUL_2(x => tao0, y=> delta0);
		RES_MUL_SCL := GF_MUL_SCL_2(x => tmp1, y=> tmp0);
		fi1         := RES_MUL1 xor RES_MUL_SCL;
		fi0         := RES_MUL0 xor RES_MUL_SCL;
		o           := fi1 & fi0;
		return o;
	end GF_MUL_4;

	function GF_SQ_SCL_4(x:  std_logic_vector(3 downto 0)) return std_logic_vector is
		variable y : std_logic_vector(3 downto 0);
		variable tao1, tao0, delta1, delta0, tmp1, tmp0: std_logic_vector(1 downto 0);
	begin
		tao1   := x(3 downto 2);
		tao0   := x(1 downto 0);
		tmp1   := tao1 xor tao0;
		tmp0   := GF_SCL_2(x =>tao0);
		delta1 := GF_SQ_2(x =>tmp1);
		delta0 := GF_SQ_2(x =>tmp0);
		y      := delta1 & delta0;
		return y;
	end GF_SQ_SCL_4;
end package body;