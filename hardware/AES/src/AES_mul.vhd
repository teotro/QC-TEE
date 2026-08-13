-------------------------------------------------------------------------------
--! @file       AES_mul.vhd
--! @brief      Galois field multiplications used by AES MixColumns operation.
--!
--! Modular multiplication in GF(2^8) with irreducible 
--! polynomial x^8 + x^4 + x^3 + x + 1.
--! Implementation of multiplication by constants from the range 1..15.
--!
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

entity AES_mul is
generic (cons   :integer := 3);
port(
    input       : in std_logic_vector(AES_SBOX_SIZE-1 downto 0);
    output      : out std_logic_vector(AES_SBOX_SIZE-1 downto 0));
end AES_mul;

-------------------------------------------------------------------------------
--! @brief  Primary architecture definition of AES_mul
-------------------------------------------------------------------------------

architecture structure of AES_mul is
begin
    c01:if cons=1 generate
        mu  : entity work.AES_mul(AES_mulx01)  port map (input=>input, output=>output);
    end generate;
    c02:if cons=2 generate
        mu  : entity work.AES_mul(AES_mulx02)  port map (input=>input, output=>output);
    end generate;
    c03:if cons=3 generate
        mu  : entity work.AES_mul(AES_mulx03)  port map (input=>input, output=>output);
    end generate;
    c04:if cons=4 generate
        mu  : entity work.AES_mul(AES_mulx04)  port map (input=>input, output=>output);
    end generate;
    c05:if cons=5 generate
        mu  : entity work.AES_mul(AES_mulx05)  port map (input=>input, output=>output);
    end generate;
    c06:if cons=6 generate
        mu  : entity work.AES_mul(AES_mulx06)  port map (input=>input, output=>output);
    end generate;
    c07:if cons=7 generate
        mu  : entity work.AES_mul(AES_mulx07)  port map (input=>input, output=>output);
    end generate;
    c08:if cons=8 generate
        mu  : entity work.AES_mul(AES_mulx08)  port map (input=>input, output=>output);
    end generate;
    c09:if cons=9 generate
        mu  : entity work.AES_mul(AES_mulx09)  port map (input=>input, output=>output);
    end generate;
    c10:if cons=10 generate
        mu  : entity work.AES_mul(AES_mulx10)  port map (input=>input, output=>output);
    end generate;
    c11:if cons=11 generate
        mu  : entity work.AES_mul(AES_mulx11)  port map (input=>input, output=>output);
    end generate;
    c12:if cons=12 generate
        mu  : entity work.AES_mul(AES_mulx12)  port map (input=>input, output=>output);
    end generate;
    c13:if cons=13 generate
        mu  : entity work.AES_mul(AES_mulx13)  port map (input=>input, output=>output);
    end generate;
    c14:if cons=14 generate
        mu  : entity work.AES_mul(AES_mulx14)  port map (input=>input, output=>output);
    end generate;
    c15:if cons=15 generate
        mu  : entity work.AES_mul(AES_mulx15)  port map (input=>input, output=>output);
    end generate;
end structure;

-------------------------------------------------------------------------------
--! @brief  Multiplication by 1 for AES_mul
-------------------------------------------------------------------------------

architecture AES_mulx01 of AES_mul is
begin
    output <= input;
end AES_mulx01;

-------------------------------------------------------------------------------
--! @brief  Multiplication by 2 for AES_mul
-------------------------------------------------------------------------------

architecture AES_mulx02 of AES_mul is
begin
    output(7) <= input(6);
    output(6) <= input(5);
    output(5) <= input(4);
    output(4) <= input(7) xor input(3);
    output(3) <= input(7) xor input(2);
    output(2) <= input(1);
    output(1) <= input(7) xor input(0);
    output(0) <= input(7);
end AES_mulx02;

-------------------------------------------------------------------------------
--! @brief  Multiplication by 3 for AES_mul
-------------------------------------------------------------------------------

architecture AES_mulx03 of AES_mul is
begin
    output(7) <= input(7) xor input(6);
    output(6) <= input(6) xor input(5);
    output(5) <= input(5) xor input(4);
    output(4) <= input(7) xor input(4) xor input(3);
    output(3) <= input(7) xor input(3) xor input(2);
    output(2) <= input(2) xor input(1);
    output(1) <= input(7) xor input(1) xor input(0);
    output(0) <= input(7) xor input(0);
end AES_mulx03;

-------------------------------------------------------------------------------
--! @brief  Multiplication by 4 for AES_mul
-------------------------------------------------------------------------------

architecture AES_mulx04 of AES_mul is
begin
    output(7) <= input(5);
    output(6) <= input(4);
    output(5) <= input(7) xor input(3);
    output(4) <= input(7) xor input(6) xor input(2);
    output(3) <= input(6) xor input(1);
    output(2) <= input(7) xor input(0);
    output(1) <= input(7) xor input(6);
    output(0) <= input(6);
end AES_mulx04;

-------------------------------------------------------------------------------
--! @brief  Multiplication by 5 for AES_mul
-------------------------------------------------------------------------------

architecture AES_mulx05 of AES_mul is
begin
    output(7) <= input(5) xor input(7);
    output(6) <= input(4) xor input(6);
    output(5) <= input(3) xor input(5) xor input(7);
    output(4) <= input(2) xor input(4) xor input(6) xor input(7);
    output(3) <= input(1) xor input(3) xor input(6);
    output(2) <= input(0) xor input(2) xor input(7);
    output(1) <= input(1) xor input(6) xor input(7);
    output(0) <= input(0) xor input(6);
end AES_mulx05;

-------------------------------------------------------------------------------
--! @brief  Multiplication by 6 for AES_mul
-------------------------------------------------------------------------------

architecture AES_mulx06 of AES_mul is
begin
    output(7) <= input(5) xor input(6);
    output(6) <= input(4) xor input(5);
    output(5) <= input(3) xor input(4) xor input(7);
    output(4) <= input(2) xor input(3) xor input(6);
    output(3) <= input(1) xor input(2) xor input(6) xor input(7);
    output(2) <= input(0) xor input(1) xor input(7);
    output(1) <= input(0) xor input(6);
    output(0) <= input(6) xor input(7);
end AES_mulx06;

-------------------------------------------------------------------------------
--! @brief  Multiplication by 7 for AES_mul
-------------------------------------------------------------------------------

architecture AES_mulx07 of AES_mul is
begin
    output(7) <= input(5) xor input(6) xor input(7);
    output(6) <= input(4) xor input(5) xor input(6);
    output(5) <= input(3) xor input(4) xor input(5) xor input(7);
    output(4) <= input(2) xor input(3) xor input(4) xor input(6);
    output(3) <= input(1) xor input(2) xor input(3) xor input(6) xor input(7);
    output(2) <= input(0) xor input(1) xor input(2) xor input(7);
    output(1) <= input(0) xor input(1) xor input(6);
    output(0) <= input(0) xor input(6) xor input(7);
end AES_mulx07;

-------------------------------------------------------------------------------
--! @brief  Multiplication by 8 for AES_mul
-------------------------------------------------------------------------------

architecture AES_mulx08 of AES_mul is
begin
    output(7) <= input(4);
    output(6) <= input(7) xor input(3);
    output(5) <= input(7) xor input(6) xor input(2);
    output(4) <= input(6) xor input(5) xor input(1);
    output(3) <= input(7) xor input(5) xor input(0);
    output(2) <= input(7) xor input(6);
    output(1) <= input(6) xor input(5);
    output(0) <= input(5);   
end AES_mulx08;

-------------------------------------------------------------------------------
--! @brief  Multiplication by 9 for AES_mul
-------------------------------------------------------------------------------

architecture AES_mulx09 of AES_mul is
begin
    output(7) <= input(7) xor input(4);
    output(6) <= input(7) xor input(6) xor input(3);
    output(5) <= input(7) xor input(6) xor input(5) xor input(2);
    output(4) <= input(6) xor input(5) xor input(4) xor input(1);
    output(3) <= input(7) xor input(5) xor input(3) xor input(0);
    output(2) <= input(7) xor input(6) xor input(2);
    output(1) <= input(6) xor input(5) xor input(1);
    output(0) <= input(5) xor input(0);
end AES_mulx09;

-------------------------------------------------------------------------------
--! @brief  Multiplication by 10 for AES_mul
-------------------------------------------------------------------------------

architecture AES_mulx10 of AES_mul is
begin
    output(7) <= input(4) xor input(6);
    output(6) <= input(3) xor input(5) xor input(7);
    output(5) <= input(2) xor input(4) xor input(6) xor input(7);
    output(4) <= input(1) xor input(3) xor input(5) xor input(6) xor input(7);
    output(3) <= input(0) xor input(2) xor input(5);
    output(2) <= input(1) xor input(6) xor input(7);
    output(1) <= input(0) xor input(5) xor input(6) xor input(7);
    output(0) <= input(5) xor input(7);
end AES_mulx10;

-------------------------------------------------------------------------------
--! @brief  Multiplication by 11 for AES_mul
-------------------------------------------------------------------------------

architecture AES_mulx11 of AES_mul is
begin
    output(7) <= input(4) xor input(6) xor input(7);
    output(6) <= input(3) xor input(5) xor input(6) xor input(7);
    output(5) <= input(2) xor input(4) xor input(5) xor input(6) xor input(7);
    output(4) <= input(1) xor input(3) xor input(4) xor input(5) xor input(6) xor input(7);
    output(3) <= input(0) xor input(2) xor input(3) xor input(5);
    output(2) <= input(1) xor input(2) xor input(6) xor input(7);
    output(1) <= input(0) xor input(1) xor input(5) xor input(6) xor input(7);
    output(0) <= input(0) xor input(5) xor input(7);
end AES_mulx11;

-------------------------------------------------------------------------------
--! @brief  Multiplication by 12 for AES_mul
-------------------------------------------------------------------------------

architecture AES_mulx12 of AES_mul is
begin
    output(7) <= input(4) xor input(5);
    output(6) <= input(3) xor input(4) xor input(7);
    output(5) <= input(2) xor input(3) xor input(6);
    output(4) <= input(1) xor input(2) xor input(5) xor input(7);
    output(3) <= input(0) xor input(1) xor input(5) xor input(6) xor input(7);
    output(2) <= input(0) xor input(6);
    output(1) <= input(5) xor input(7);
    output(0) <= input(5) xor input(6);
end AES_mulx12;

-------------------------------------------------------------------------------
--! @brief  Multiplication by 13 for AES_mul
-------------------------------------------------------------------------------

architecture AES_mulx13 of AES_mul is
begin
    output(7) <= input(4) xor input(5) xor input(7);
    output(6) <= input(3) xor input(4) xor input(6) xor input(7);
    output(5) <= input(2) xor input(3) xor input(5) xor input(6);
    output(4) <= input(1) xor input(2) xor input(4) xor input(5) xor input(7);
    output(3) <= input(0) xor input(1) xor input(3) xor input(5) xor input(6) xor input(7);
    output(2) <= input(0) xor input(2) xor input(6);
    output(1) <= input(1) xor input(5) xor input(7);
    output(0) <= input(0) xor input(5) xor input(6);
end AES_mulx13;

-------------------------------------------------------------------------------
--! @brief  Multiplication by 14 for AES_mul
-------------------------------------------------------------------------------

architecture AES_mulx14 of AES_mul is
begin
    output(7) <= input(4) xor input(5) xor input(6);
    output(6) <= input(3) xor input(4) xor input(5) xor input(7);
    output(5) <= input(2) xor input(3) xor input(4) xor input(6);
    output(4) <= input(1) xor input(2) xor input(3) xor input(5);
    output(3) <= input(0) xor input(1) xor input(2) xor input(5) xor input(6);
    output(2) <= input(0) xor input(1) xor input(6);
    output(1) <= input(0) xor input(5);
    output(0) <= input(5) xor input(6) xor input(7);
end AES_mulx14;

-------------------------------------------------------------------------------
--! @brief  Multiplication by 15 for AES_mul
-------------------------------------------------------------------------------

architecture AES_mulx15 of AES_mul is
begin
    output(7) <= input(4) xor input(5) xor input(6) xor input(7);
    output(6) <= input(3) xor input(4) xor input(5) xor input(6) xor input(7);
    output(5) <= input(2) xor input(3) xor input(4) xor input(5) xor input(6);
    output(4) <= input(1) xor input(2) xor input(3) xor input(4) xor input(5);
    output(3) <= input(0) xor input(1) xor input(2) xor input(3) xor input(5) xor input(6);
    output(2) <= input(0) xor input(1) xor input(2) xor input(6);
    output(1) <= input(0) xor input(1) xor input(6);
    output(0) <= input(0) xor input(5) xor input(6) xor input(7);
end AES_mulx15;