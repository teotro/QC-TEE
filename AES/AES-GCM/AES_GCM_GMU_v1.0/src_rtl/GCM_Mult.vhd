-------------------------------------------------------------------------------
--! @file       GCM_Mult.vhd
--! @author     Ekawat (ice) Homsirikamol
--! @brief      GCM MULT implementation for GHASH
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity GCM_Mult is

    port (
        --! Global signals
        clk             :   in  std_logic;
        rst             :   in  std_logic;

        --! Ctrl signals
        start           :   in  std_logic;
        clr             :   in  std_logic;
        finished        :   out std_logic;

        --! Data/key signals
        xx              :   in  std_logic_vector(128            -1 downto 0);
        hh              :   in  std_logic_vector(128            -1 downto 0);
        do              :   out std_logic_vector(128            -1 downto 0)
    );
end GCM_Mult;

--! Satoh's Sequential multiplier-adder
--! Based on Fig. 7 in "High-Performance Hardware Architectures for Galois Counter Mode" (with slight modification)

architecture ice_seq of GCM_Mult is
    function extend_bit ( x : std_logic; size : integer ) return std_logic_vector is
        variable ret : std_logic_vector(size-1 downto 0);
    begin
        for i in 0 to size-1 loop
            ret(i) := x;
        end loop;
        return ret;
    end function extend_bit;

    constant VERT_FF                : integer                                                        := 3;
    constant ONES                   : std_logic_vector(VERT_FF                          -1 downto 0) := (others => '1');
    constant HHWIDTH                : integer                                                        := 128/(2**VERT_FF);

    --! Control signals
    type state_type is (S_WAIT_START, S_COMPUTE);
    signal state                    : state_type;
    signal ctr                      : std_logic_vector(VERT_FF           -1 downto 0);
    signal calc                     : std_logic;
    signal start_delay              : std_logic;

    --! Datapath signals
    signal vv_reg                   : std_logic_vector(128                              -1 downto 0);
    signal zz_reg                   : std_logic_vector(128                              -1 downto 0);
    signal hh_sel                   : std_logic_vector(HHWIDTH                          -1 downto 0);
    signal hh_reg                   : std_logic_vector(HHWIDTH                          -1 downto 0);

    type array_type is array (0 to HHWIDTH-1 ) of std_logic_vector(127 downto 0);
    signal zz                       : array_type;
    signal vv                       : array_type;
begin
    p_reg:
    process( clk )
    begin
        if rising_edge( clk ) then
            if rst = '1' or clr = '1' then
                vv_reg  <= (others => '0');
                zz_reg  <= (others => '0');
            elsif start = '1' then
                vv_reg  <= xx;
                zz_reg  <= (others => '0');
            elsif calc = '1' then
                vv_reg  <= vv(HHWIDTH-1);
                zz_reg  <= zz(HHWIDTH-1);
            end if;

            hh_reg      <= hh_sel;
            start_delay <= start;
        end if;
    end process;

    fsm:
    process(clk)
    begin
        if rising_edge( clk ) then
            if rst = '1' or clr = '1' then
                state    <= S_WAIT_START;
                calc     <= '0';
                ctr      <= (others => '0');
                finished <= '0';
            else
                finished <= '0';
                case state is
                    when S_WAIT_START =>
                        if start = '1' then
                            state <= S_COMPUTE;
                            calc  <= '1';
                            ctr   <= ctr + 1;
                        else
                            calc  <= '0';
                        end if;
                    when S_COMPUTE =>
                        if ctr = ONES then
                            state    <= S_WAIT_START;
                            ctr      <= (others => '0');
                            finished <= '1';
                        else
                            ctr      <= ctr + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;

    with ctr(VERT_FF-1 downto 0) select
    hh_sel <=   hh(128-(0*HHWIDTH)-1 downto 128-(1*HHWIDTH)) when "000",
                hh(128-(1*HHWIDTH)-1 downto 128-(2*HHWIDTH)) when "001",
                hh(128-(2*HHWIDTH)-1 downto 128-(3*HHWIDTH)) when "010",
                hh(128-(3*HHWIDTH)-1 downto 128-(4*HHWIDTH)) when "011",
                hh(128-(4*HHWIDTH)-1 downto 128-(5*HHWIDTH)) when "100",
                hh(128-(5*HHWIDTH)-1 downto 128-(6*HHWIDTH)) when "101",
                hh(128-(6*HHWIDTH)-1 downto 128-(7*HHWIDTH)) when "110",
                hh(128-(7*HHWIDTH)-1 downto 128-(8*HHWIDTH)) when others;

    --! First stage
    g0_vv0:
    for j in 127 downto 0 generate
        vv0_j127:
        if j  = 127 generate
            vv(0)(j) <=  vv_reg(  0)                    when start_delay = '0' else vv_reg(j);
        end generate;
        vv0_jprop:
        if j  = 126 or  j  = 125 or  j  = 120 generate
            vv(0)(j) <= (vv_reg(  0) xor vv_reg(j+1))   when start_delay = '0' else vv_reg(j);
        end generate;
        vv0_jx:
        if j /= 127 and j /= 126 and j /= 125 and j /= 120 generate
            vv(0)(j) <=               vv_reg(j+1)       when start_delay = '0' else vv_reg(j);
        end generate;
    end generate;
    zz(0) <= zz_reg xor (extend_bit(hh_reg(HHWIDTH-1), 128) and vv(0));

    --! Subsequent stages
    g1:
    for i in 1 to HHWIDTH-1 generate
        g2:
        for j in 127 downto 0 generate
            g2_j127:
            if j  = 127 generate
                vv(i)(j) <=  vv(i-1)(  0)                  ;
            end generate;
            g2_jprop:
            if j  = 126 or  j  = 125 or  j  = 120 generate
                vv(i)(j) <= (vv(i-1)(  0) xor vv(i-1)(j+1));
            end generate;
            g2_jx:
            if j /= 127 and j /= 126 and j /= 125 and j /= 120 generate
                vv(i)(j) <=                   vv(i-1)(j+1);
            end generate;
        end generate;
        zz(i) <= zz(i-1) xor (extend_bit(hh_reg(HHWIDTH-i-1), 128) and vv(i));
    end generate;

    do    <= zz_reg;
end ice_seq;


architecture ice_parallel of GCM_Mult is
    function extend_bit ( x : std_logic; size : integer ) return std_logic_vector is
        variable ret : std_logic_vector(size-1 downto 0);
    begin
        for i in 0 to size-1 loop
            ret(i) := x;
        end loop;
        return ret;
    end function extend_bit;

    --! Datapath signals
    signal reg    :  std_logic_vector(128                           -1 downto 0);

    type mult_type is array (0 to 127) of std_logic_vector(127 downto 0);
    signal vv     :  mult_type;
    signal zz     :  mult_type;
begin
    vv(0) <= xx;
    zz(0) <= extend_bit(hh(127), 128) and vv(0);
    g1:
    for i in 1 to 127 generate
        zz(i) <= zz(i-1) xor (extend_bit(hh(127-i), 128) and vv(i));
        g2:
        for j in 127 downto 0 generate
            g2_j127:
            if j  = 127 generate
                vv(i)(j) <=  vv(i-1)(  0)                  ;
            end generate;
            g2_jprop:
            if j  = 126 or  j  = 125 or  j  = 120 generate
                vv(i)(j) <= (vv(i-1)(  0) xor vv(i-1)(j+1));
            end generate;
            g2_jx:
            if j /= 127 and j /= 126 and j /= 125 and j /= 120 generate
                vv(i)(j) <=                   vv(i-1)(j+1);
            end generate;
        end generate;
    end generate;

    p_reg:
    process( clk )
    begin
        if rising_edge( clk ) then
            if rst = '1' or clr = '1' then
                reg <= (others => '0');
            elsif start = '1' then
                reg <= zz(127);
            end if;
        end if;
    end process;

    do       <= reg;
    finished <= start;
end ice_parallel;


--! Satoh's Sequential multiplier-adder
--! Based on Fig. 7 in "High-Performance Hardware Architectures for Galois Counter Mode"

architecture satoh_parallel of GCM_Mult is
    function extend_bit ( x : std_logic; size : integer ) return std_logic_vector is
        variable ret : std_logic_vector(size-1 downto 0);
    begin
        for i in 0 to size-1 loop
            ret(i) := x;
        end loop;
        return ret;
    end function extend_bit;

    --! Datapath signals
    signal reg    :  std_logic_vector(128                           -1 downto 0);

    type mult_type is array (0 to 127) of std_logic_vector(127 downto 0);
    signal ss     :  mult_type;
begin
    ss(0) <= hh and extend_bit(xx(0), 128);

    g1:
    for i in 1 to 127 generate
        g2:
        for j in 127 downto 0 generate
            g2_j127:
            if j  = 127 generate
                ss(i)(j) <=  ss(i-1)(  0)                   xor (xx(i) and hh(j));
            end generate;
            g2_jprop:
            if j  = 126 or  j  = 125 or  j  = 120 generate
                ss(i)(j) <= (ss(i-1)(  0) xor ss(i-1)(j+1)) xor (xx(i) and hh(j));
            end generate;
            g2_jx:
            if j /= 127 and j /= 126 and j /= 125 and j /= 120 generate
                ss(i)(j) <=                   ss(i-1)(j+1)  xor (xx(i) and hh(j));
            end generate;
        end generate;
    end generate;

    p_reg:
    process( clk )
    begin
        if rising_edge( clk ) then
            if rst = '1' or clr = '1' then
                reg <= (others => '0');
            elsif start = '1' then
                reg <= ss(127);
            end if;
        end if;
    end process;

    do       <= reg;
    finished <= start;

end satoh_parallel;

--! Ice's design
architecture ice of GCM_Mult is
    type table_type is array (0 to 7, 0 to 15) of std_logic_vector(127 downto 0);

    function generate_table ( h : std_logic_vector(127 downto 0) ) return table_type is
        variable tab : table_type;
        variable xshf : std_logic_vector(127 downto 0);
    begin
        for i in 0 to 15 loop
            for j in 0 to 7 loop
                if i = 0 and j = 0 then
                    tab(7-j,15-i) := h;
                elsif j = 0 then
                    xshf := '0' & tab(0,15-i+1)(127 downto 1);
                    if ( tab(0,15-i+1)(0) = '1' ) then
                        tab(7-j,15-i) := xshf xor x"E1000000000000000000000000000000";
                    else
                        tab(7-j,15-i) := xshf;
                    end if;
                else
                    xshf := '0' & tab(7-j+1,15-i)(127 downto 1);
                    if ( tab(7-j+1,15-i)(0) = '1' ) then
                        tab(7-j,15-i) := xshf xor x"E1000000000000000000000000000000";
                    else
                        tab(7-j,15-i) := xshf;
                    end if;
                end if;
            end loop;
        end loop;
        return tab;
    end function generate_table;

    function get_result ( a : std_logic_vector(127 downto 0); b : std_logic_vector) return std_logic_vector is
        variable tab    : table_type;
        variable tmp    : std_logic_vector(  7 downto 0);
        variable result : std_logic_vector(127 downto 0);
        variable row    : std_logic_vector(127 downto 0);
    begin
        tab    := generate_table ( a );
        result := (others => '0');
        for i in 0 to 15 loop
            tmp := b(8*i+7 downto 8*i);
            row := (others => '0');
            --! Add rows
            for j in 0 to 7 loop
                if (tmp(j) = '1') then
                    row := row xor tab(j, i);
                end if;
            end loop;
            result := result xor row;
        end loop;
        return result;
    end get_result;

    signal reg : std_logic_vector(127 downto 0);
begin
    p_reg:
    process( clk )
    begin
        if rising_edge( clk ) then
            if rst = '1' or clr = '1' then
                reg <= (others => '0');
            elsif start = '1' then
                reg <= get_result( hh, xx );
            end if;
        end if;
    end process;
    do       <= reg;
    finished <= start;
end ice;