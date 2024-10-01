-------------------------------------------------------------------------------
--! @file       CipherCore_Datapath.vhd
--! @author     Ekawat (ice) Homsirikamol
--! @brief      Datapath unit for AES-GCM
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.AEAD_pkg.all;

entity CipherCore_Datapath is
    generic (
        G_MAX_LEN           : integer := SINGLE_PASS_MAX
    );
    port    (
        clk                 : in  std_logic;
        rst                 : in  std_logic;

        --! Input
        bdi                 : in  std_logic_vector(128           -1 downto 0);
        bdi_valid_bytes     : in  std_logic_vector(128/8         -1 downto 0);
        key                 : in  std_logic_vector(32            -1 downto 0);
        len_a               : in  std_logic_vector(G_MAX_LEN     -1 downto 0);
        len_d               : in  std_logic_vector(G_MAX_LEN     -1 downto 0);

        --! Control        
        aes_done            : out std_logic;
        mult_done           : out std_logic;
        en_key              : in  std_logic;
        en_hashkey          : in  std_logic;
        en_npub             : in  std_logic;
        en_ctr              : in  std_logic;
        en_aes              : in  std_logic;
        en_mult             : in  std_logic;
        clr_hashkey         : in  std_logic;
        clr_ctr             : in  std_logic;
        clr_mult            : in  std_logic;
        sel_tag             : in  std_logic;
        sel_mux1            : in  std_logic;
        sel_mux2            : in  std_logic_vector(  2           -1 downto 0);
        sel_aes             : in  std_logic;
        bdi_eoi             : in  std_logic;
        msg_auth_valid      : out std_logic;

        --! Output
        bdo                 : out std_logic_vector(128           -1 downto 0)
    );
end entity CipherCore_Datapath;

architecture structure of CipherCore_Datapath is
    constant ZEROS          : std_logic_vector(128              -1 downto 0)
                                := (others => '0');
    signal reg_ctr          : std_logic_vector( 32              -1 downto 0);

    signal mux_aes          : std_logic_vector(128              -1 downto 0);
    signal aes_do           : std_logic_vector(128              -1 downto 0);

    signal reg_key          : std_logic_vector(128              -1 downto 0);
    signal reg_hashkey      : std_logic_vector(128              -1 downto 0);
    signal reg_ek0          : std_logic_vector(128              -1 downto 0);
    signal reg_npub         : std_logic_vector( 96              -1 downto 0);

    signal mult_do          : std_logic_vector(128              -1 downto 0);
    signal xor1             : std_logic_vector(128              -1 downto 0);
    signal xor2             : std_logic_vector(128              -1 downto 0);
    signal mux1             : std_logic_vector(128              -1 downto 0);
    signal mux2             : std_logic_vector(128              -1 downto 0);

    signal bdi_valid_bits   : std_logic_vector(128              -1 downto 0);

    signal len              : std_logic_vector(128              -1 downto 0);
    signal tag_data         : std_logic_vector(128              -1 downto 0);
begin
    pRegs:
    process(clk)
    begin
        if rising_edge(clk) then
            --! Hash Key
            if (clr_hashkey = '1') then
                reg_hashkey <= (others => '0');
            elsif (en_hashkey = '1') then
                reg_hashkey <= aes_do;
            end if;            
            --! Ctr
            if (clr_ctr = '1') then
                reg_ctr <= (0 => '1', others => '0');                
            elsif (en_ctr = '1') then
                reg_ctr <= std_logic_vector(unsigned(reg_ctr) + 1);
            end if;
            --! Key
            if (en_key = '1') then
                reg_key <= reg_key(95 downto 0) & key;
            end if;
            --! Npub
            if (en_npub = '1') then
                reg_npub <= bdi(127 downto 32);
            end if;
        end if;
    end process;

    mux_aes <= (others => '0') when sel_aes = '1' else (reg_npub & reg_ctr);

    uAES: entity work.AES_Enc_KOF(structure)
    generic map (G_OBUF => False)
    port map (clk=>clk, rst=>rst,
              start=>en_aes, ready=>open, done=>aes_done,
              din =>mux_aes,  key=>reg_key, dout=>aes_do);

    uMult: entity work.GCM_Mult(ice_seq)
    port map (clk=>clk, rst=>rst,
              clr=>clr_mult, start=>en_mult, xx=>xor2, hh=>reg_hashkey,
              finished=> mult_done, do=> mult_do);

    mux1 <= (others => '0') when sel_mux1 = '1' else aes_do;

    genXor:
    for i in 15 downto 0 generate
        bdi_valid_bits(8*i+7 downto 8*i) <= (others => bdi_valid_bytes(i));
        xor1(8*i+7 downto 8*i) <=  (bdi(8*i+7 downto 8*i)
                                    xor mux1(8*i+7 downto 8*i))
                                        and bdi_valid_bits(8*i+7 downto 8*i);
    end generate;

    len <= ZEROS(63 downto G_MAX_LEN) & len_a 
           & ZEROS(63 downto G_MAX_LEN) & len_d;

    with sel_mux2(1 downto 0) select
    mux2 <= xor1            when "00", --! Encryption
            bdi             when "01", --! Decryption
            len             when "10", --! Last GCM_MULT
            (others => '0') when others; --! Tag output
    xor2 <= mult_do xor mux2;

    bdo      <= tag_data when sel_tag = '1' else xor1;

    --! Note: Perform tag calculation here instead of taking values from
    --!       XOR2 to reduce critical path (especially during tag auth)
    tag_data <= mult_do xor aes_do;

    msg_auth_valid <= '1' when tag_data = bdi else '0';
end architecture structure;