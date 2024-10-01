-------------------------------------------------------------------------------
--! @file       AES_Enc_tb.vhd
--! @brief      Test bench for encryption only AES-ECB mode.
--! 
--! The test vectors used in this testbench were obtained from:
--! the Appendix in http://csrc.nist.gov/publications/fips/fips197/fips-197.pdf    
--!
--! @project    CAESAR Candidate Evaluation
--! @author     Ekawat (ice) Homsirikamol
--! @version    1.0
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

entity AES_Enc_tb is
end AES_Enc_tb;

-------------------------------------------------------------------------------
--! @brief  Architecture definition of AES_Enc_tb
-------------------------------------------------------------------------------

architecture sim of AES_Enc_tb is
    signal rst          : std_logic := '0';
    signal clk          : std_logic := '0';
    signal init         : std_logic := '0';
    signal start, ready, done, done_init : std_logic;
    signal di, do, key  : std_logic_vector(127 downto 0);

    signal   enClock    : boolean := TRUE;
    constant clk_period : time := 20 ns;
    constant numTVs     : integer := 2;
    type tTestVector is record
        input       : std_logic_vector(127 downto 0);
        key         : std_logic_vector(127 downto 0);
        exp_output  : std_logic_vector(127 downto 0);
    end record tTestVector;
    type tTestVectorArray is array (0 to numTVs-1) of tTestVector;
    constant TV_0 : tTestVector := (
            input       => (others => '0'), 
            key         => (others => '0'), 
            exp_output  => (others => '0')
        );
    constant tv : tTestVectorArray := (
        --! Appendix C.1
        0 => (  input       => x"00112233445566778899AABBCCDDEEFF",
                key         => x"000102030405060708090A0B0C0D0E0F",
                exp_output  => x"69C4E0D86A7B0430D8CDB78070B4C55A" ),
        --! Appendix B
        1 => (  input       => x"3243F6A8885A308D313198A2E0370734",
                key         => x"2B7E151628AED2A6ABF7158809CF4F3C",
                exp_output  => x"3925841D02DC09FBDC118597196A0B32"),
        others => TV_0
        );
begin   
    uut:
    entity work.AES_Enc
    port map (
        rst       => rst,
        clk       => clk,
        start     => start,
        ready     => ready,
        init      => init,
        done      => done,
        done_init => done_init,
        din       => di,
        dout      => do,
        key       => key
    );
    
    pClk:
    process
    begin
        while enClock = TRUE loop
            wait for clk_period/2;
            clk <= not clk;
        end loop;
        wait;
    end process;

    pSim:
    process
        variable is_init         : boolean;
        variable cnt_test        : integer := 0;
        variable cnt_test_failed : integer := 0;
        variable cnt_test_passed : integer := 0;
    begin
        report "    Initializing circuit...";
        rst   <= '1';
        start <= '0';
        wait for clk_period;
        rst   <= '0';
        wait for 4*clk_period;

        report "    Performing test...";
        for i in 0 to numTVs-1 loop
            --! Check whether initialization of new key is required
            if i = 0 then                       --! First key
                is_init := TRUE;
            elsif tv(i).key /= tv(i-1).key then --! Subsequent key is the same
                is_init := TRUE;
            else
                is_init := FALSE;
            end if;

            --! Perform initialization
            if is_init = TRUE then
                init <= '1';
                key  <= tv(i).key;
                report "    [Start] Initialize key number: " & integer'image(i);
                wait for clk_period;
                init <= '0';
                key  <= (others => '0');
                wait until done_init = '1';
                wait for clk_period*3/4;
                report "    [Done]" & time'image(now);
            end if;

            --! Check test vector
            di      <= tv(i).input;
            start   <= '1';
            report "    [Start] Test number: " & integer'image(i);
            wait for clk_period;
            di      <= (others => '0');
            start   <= '0';

            --! Verifying output
            wait until done = '1';
            wait for clk_period*3/4;
            cnt_test := cnt_test + 1;
            if (tv(i).exp_output = do) then
                report "    [Done] Test " & integer'image(i) & " |passed|.";
                cnt_test_passed := cnt_test_passed + 1;
            else
                report "    [Done] Test " & integer'image(i) & " |failed| at time " & time'image(now);
                cnt_test_failed := cnt_test_failed + 1;
            end if;
        end loop;

        wait for clk_period*5;
        enClock <= FALSE;
        report "    ===== [Done]! Test completed. =====";
        report "    [info] Total tests performed : " & integer'image(cnt_test);
        report "    [info] Number of failures    : " & integer'image(cnt_test_failed);
        report "    [info] Number of passes      : " & integer'image(cnt_test_passed);
        if (cnt_test_failed = 0) then            
            report "    [Summary] Congrats! All tests passed.";
        else
            report "    [Summary] Boohoo! Something failed. =(";
        end if;
        wait;
    end process;

    pCounter:
    process(clk)
        variable is_proc        : boolean;
        variable is_init        : boolean;
        variable procCounter    : integer;
        variable initCounter    : integer;
    begin
        --! Check start signal at the rising edge
        if rising_edge(clk) then
            if (init = '1') then
                initCounter := 0;
                is_init     := TRUE;
            elsif (start = '1') then
                procCounter := 0;
                is_proc     := TRUE;
            end if;
        end if;

        --! Check output status at the falling edge
        if falling_edge(clk) then
            if is_proc = TRUE then
                procCounter := procCounter + 1;
                if done = '1' then
                    is_proc := FALSE;
                    report "    [info] Processing latency = " & integer'image(procCounter);
                end if;
            end if;
            if is_init = TRUE then
                initCounter := initCounter + 1;
                if done_init = '1' then
                    is_init := FALSE;
                    report "    [info] Initialization latency = " & integer'image(initCounter);
                end if;
            end if;
        end if;
    end process;

end architecture sim;