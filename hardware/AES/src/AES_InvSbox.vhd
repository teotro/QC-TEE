-------------------------------------------------------------------------------
--! @file       AES_InvSbox.vhd
--! @brief      An inverted SBOX used by AES implemented using
--!             distributed memory
--! @project    CAESAR Candidate Evaluation
--! @author     Marcin Rogawski
--!             Ekawat (ice) Homsirikamol
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

entity AES_InvSbox is    
    port(
        input 		: in  std_logic_vector(AES_SBOX_SIZE-1 downto 0);
        output 		: out std_logic_vector(AES_SBOX_SIZE-1 downto 0)
    );
end AES_InvSbox;

-------------------------------------------------------------------------------
--! @brief  Look-Table based implementation
-------------------------------------------------------------------------------

architecture distributed_rom of AES_InvSbox is
    type mem is array (0 to 2**AES_SBOX_SIZE-1) of std_logic_vector(AES_SBOX_SIZE-1 downto 0);
    constant sbox_rom : mem := (
	0   => x"52",1   => x"09",2   => x"6a",3   => x"d5",4   => x"30",5   => x"36",6   => x"a5",7   => x"38",8   => x"bf",9   => x"40",10  => x"a3",11  => x"9e",12  => x"81",13  => x"f3",14  => x"d7",15  => x"fb",
	16  => x"7c",17  => x"e3",18  => x"39",19  => x"82",20  => x"9b",21  => x"2f",22  => x"ff",23  => x"87",24  => x"34",25  => x"8e",26  => x"43",27  => x"44",28  => x"c4",29  => x"de",30  => x"e9",31  => x"cb",
	32  => x"54",33  => x"7b",34  => x"94",35  => x"32",36  => x"a6",37  => x"c2",38  => x"23",39  => x"3d",40  => x"ee",41  => x"4c",42  => x"95",43  => x"0b",44  => x"42",45  => x"fa",46  => x"c3",47  => x"4e",
	48  => x"08",49  => x"2e",50  => x"a1",51  => x"66",52  => x"28",53  => x"d9",54  => x"24",55  => x"b2",56  => x"76",57  => x"5b",58  => x"a2",59  => x"49",60  => x"6d",61  => x"8b",62  => x"d1",63  => x"25",
	64  => x"72",65  => x"f8",66  => x"f6",67  => x"64",68  => x"86",69  => x"68",70  => x"98",71  => x"16",72  => x"d4",73  => x"a4",74  => x"5c",75  => x"cc",76  => x"5d",77  => x"65",78  => x"b6",79  => x"92",
	80  => x"6c",81  => x"70",82  => x"48",83  => x"50",84  => x"fd",85  => x"ed",86  => x"b9",87  => x"da",88  => x"5e",89  => x"15",90  => x"46",91  => x"57",92  => x"a7",93  => x"8d",94  => x"9d",95  => x"84",
	96  => x"90",97  => x"d8",98  => x"ab",99  => x"00",100 => x"8c",101 => x"bc",102 => x"d3",103 => x"0a",104 => x"f7",105 => x"e4",106 => x"58",107 => x"05",108 => x"b8",109 => x"b3",110 => x"45",111 => x"06",
	112 => x"d0",113 => x"2c",114 => x"1e",115 => x"8f",116 => x"ca",117 => x"3f",118 => x"0f",119 => x"02",120 => x"c1",121 => x"af",122 => x"bd",123 => x"03",124 => x"01",125 => x"13",126 => x"8a",127 => x"6b",
	128 => x"3a",129 => x"91",130 => x"11",131 => x"41",132 => x"4f",133 => x"67",134 => x"dc",135 => x"ea",136 => x"97",137 => x"f2",138 => x"cf",139 => x"ce",140 => x"f0",141 => x"b4",142 => x"e6",143 => x"73",
	144 => x"96",145 => x"ac",146 => x"74",147 => x"22",148 => x"e7",149 => x"ad",150 => x"35",151 => x"85",152 => x"e2",153 => x"f9",154 => x"37",155 => x"e8",156 => x"1c",157 => x"75",158 => x"df",159 => x"6e",
	160 => x"47",161 => x"f1",162 => x"1a",163 => x"71",164 => x"1d",165 => x"29",166 => x"c5",167 => x"89",168 => x"6f",169 => x"b7",170 => x"62",171 => x"0e",172 => x"aa",173 => x"18",174 => x"be",175 => x"1b",
	176 => x"fc",177 => x"56",178 => x"3e",179 => x"4b",180 => x"c6",181 => x"d2",182 => x"79",183 => x"20",184 => x"9a",185 => x"db",186 => x"c0",187 => x"fe",188 => x"78",189 => x"cd",190 => x"5a",191 => x"f4",
	192 => x"1f",193 => x"dd",194 => x"a8",195 => x"33",196 => x"88",197 => x"07",198 => x"c7",199 => x"31",200 => x"b1",201 => x"12",202 => x"10",203 => x"59",204 => x"27",205 => x"80",206 => x"ec",207 => x"5f",
	208 => x"60",209 => x"51",210 => x"7f",211 => x"a9",212 => x"19",213 => x"b5",214 => x"4a",215 => x"0d",216 => x"2d",217 => x"e5",218 => x"7a",219 => x"9f",220 => x"93",221 => x"c9",222 => x"9c",223 => x"ef",
	224 => x"a0",225 => x"e0",226 => x"3b",227 => x"4d",228 => x"ae",229 => x"2a",230 => x"f5",231 => x"b0",232 => x"c8",233 => x"eb",234 => x"bb",235 => x"3c",236 => x"83",237 => x"53",238 => x"99",239 => x"61",
	240 => x"17",241 => x"2b",242 => x"04",243 => x"7e",244 => x"ba",245 => x"77",246 => x"d6",247 => x"26",248 => x"e1",249 => x"69",250 => x"14",251 => x"63",252 => x"55",253 => x"21",254 => x"0c",255 => x"7d");
begin
    output <= sbox_rom(to_integer(unsigned(input)));
end distributed_rom;

-------------------------------------------------------------------------------
--! @brief  Logic based implementation
-------------------------------------------------------------------------------

architecture logic of AES_InvSbox is
    signal after_inv_affine : std_logic_vector(AES_SBOX_SIZE-1 downto 0);
    signal after_mul_invmx  : std_logic_vector(AES_SBOX_SIZE-1 downto 0);
    signal after_invgf8     : std_logic_vector(AES_SBOX_SIZE-1 downto 0);
begin
    after_inv_affine  <= input xor AFFINE_C;
    after_mul_invmx   <= MUL_INVMX(after_inv_affine);
    after_invgf8      <= GF_INV_GF8(after_mul_invmx);
    output            <= MUL_X(after_invgf8);
end logic;
