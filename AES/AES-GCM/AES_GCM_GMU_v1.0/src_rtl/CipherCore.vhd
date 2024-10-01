-------------------------------------------------------------------------------
--! @file       CipherCore.vhd
--! @author     Ekawat (ice) Homsirikamol
--! @brief      Top-level CipherCore for AES-GCM
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use work.AEAD_pkg.all;

entity CipherCore is
    generic (
        --! Reset behavior
        G_ASYNC_RSTN    : boolean := False; --! Async active low reset
        --! Block size (bits)
        G_DBLK_SIZE     : integer := 128;   --! Data
        G_KEY_SIZE      : integer := 32;    --! Key
        G_TAG_SIZE      : integer := 128;   --! Tag
        --! The number of bits required to hold block size expressed in
        --! bytes = log2_ceil(G_DBLK_SIZE/8)
        G_LBS_BYTES      : integer := 4;
        --! Maximum supported AD/message/ciphertext length = 2^G_MAX_LEN-1
        G_MAX_LEN       : integer := SINGLE_PASS_MAX
    );
    port (
        --! Global
        clk             : in  std_logic;
        rst             : in  std_logic;
        --! PreProcessor (data)
        key             : in  std_logic_vector(G_KEY_SIZE       -1 downto 0);
        bdi             : in  std_logic_vector(G_DBLK_SIZE      -1 downto 0);
        --! PreProcessor (controls)
        key_ready       : out std_logic;
        key_valid       : in  std_logic;
        key_update      : in  std_logic;
        decrypt         : in  std_logic;
        bdi_ready       : out std_logic;
        bdi_valid       : in  std_logic;
        bdi_type        : in  std_logic_vector(3                -1 downto 0);
        bdi_partial     : in  std_logic;
        bdi_eot         : in  std_logic;
        bdi_eoi         : in  std_logic;
        bdi_size        : in  std_logic_vector(G_LBS_BYTES+1    -1 downto 0);
        bdi_valid_bytes : in  std_logic_vector(G_DBLK_SIZE/8    -1 downto 0);
        bdi_pad_loc     : in  std_logic_vector(G_DBLK_SIZE/8    -1 downto 0);
        --! PostProcessor
        bdo             : out std_logic_vector(G_DBLK_SIZE      -1 downto 0);
        bdo_valid       : out std_logic;
        bdo_ready       : in  std_logic;
        bdo_size        : out std_logic_vector(G_LBS_BYTES+1    -1 downto 0);
        msg_auth_done   : out std_logic;
        msg_auth_valid  : out std_logic
    );
end entity CipherCore;

architecture structure of CipherCore is
    signal aes_done             : std_logic;
    signal mult_done            : std_logic;
    signal en_key               : std_logic;
    signal en_hashkey           : std_logic;
    signal en_npub              : std_logic;
    signal en_ctr               : std_logic;
    signal en_aes               : std_logic;
    signal en_mult              : std_logic;
    signal clr_hashkey          : std_logic;
    signal clr_ctr              : std_logic;
    signal clr_mult             : std_logic;
    signal sel_tag              : std_logic;
    signal sel_mux1             : std_logic;
    signal sel_mux2             : std_logic_vector(2            -1 downto 0);
    signal sel_aes              : std_logic;
    signal len_a                : std_logic_vector(G_MAX_LEN    -1 downto 0);
    signal len_d                : std_logic_vector(G_MAX_LEN    -1 downto 0);
begin

    u_cc_dp:
    entity work.CipherCore_Datapath(structure)
    generic map (G_MAX_LEN => G_MAX_LEN)
    port map (
        clk             => clk              ,
        rst             => rst              ,

        --! Input Processor
        key             => key              ,
        bdi             => bdi              ,
        bdi_valid_bytes => bdi_valid_bytes  ,

        --! Output Processor
        bdo             => bdo              ,
        msg_auth_valid  => msg_auth_valid   ,

        --! Controller
        len_a           => len_a            ,
        len_d           => len_d            ,
        aes_done        => aes_done         ,
        mult_done       => mult_done        ,

        en_key          => en_key           ,
        en_hashkey      => en_hashkey       ,
        en_npub         => en_npub          ,
        en_ctr          => en_ctr           ,
        en_aes          => en_aes           ,
        en_mult         => en_mult          ,
        clr_hashkey     => clr_hashkey      ,
        clr_ctr         => clr_ctr          ,
        clr_mult        => clr_mult         ,
        sel_tag         => sel_tag          ,
        sel_mux1        => sel_mux1         ,
        sel_mux2        => sel_mux2         ,
        sel_aes         => sel_aes          ,
        bdi_eoi         => bdi_eoi
    );

    u_cc_ctrl:
    entity work.CipherCore_Control(behavior)
    generic map (G_MAX_LEN => G_MAX_LEN)
    port map (
        clk             => clk              ,
        rst             => rst              ,

        --! Input
        key_ready       => key_ready        ,
        key_valid       => key_valid        ,
        key_update      => key_update       ,
        mode            => decrypt          ,
        bdi_ready       => bdi_ready        ,
        bdi_valid       => bdi_valid        ,
        bdi_type        => bdi_type         ,
        bdi_eot         => bdi_eot          ,
        bdi_eoi         => bdi_eoi          ,
        bdi_size        => bdi_size         ,

        --! Datapath
        len_a           => len_a            ,
        len_d           => len_d            ,
        aes_done        => aes_done         ,
        mult_done       => mult_done        ,
        en_key          => en_key           ,
        en_hashkey      => en_hashkey       ,
        en_npub         => en_npub          ,
        en_ctr          => en_ctr           ,
        en_aes          => en_aes           ,
        en_mult         => en_mult          ,
        clr_hashkey     => clr_hashkey      ,
        clr_ctr         => clr_ctr          ,
        clr_mult        => clr_mult         ,
        sel_tag         => sel_tag          ,
        sel_mux1        => sel_mux1         ,
        sel_mux2        => sel_mux2         ,
        sel_aes         => sel_aes          ,        

        --! Output
        msg_auth_done   => msg_auth_done    ,
        bdo_ready       => bdo_ready        ,
        bdo_valid       => bdo_valid
    );
end structure;