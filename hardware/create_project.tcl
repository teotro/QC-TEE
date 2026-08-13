set script_dir [file dirname [file normalize [info script]]]
set proj_name  "qc_tee"
set proj_dir   [file normalize "$script_dir/../vivado_proj"]
set part       "xc7a35tcpg236-1"

create_project $proj_name $proj_dir -part $part -force

set_property target_language Verilog [current_project]

set verilog_sources [list \
    "$script_dir/clog2.v" \
    "$script_dir/shifter.v" \
    "$script_dir/main_controller.v" \
    "$script_dir/dec_enc_engine.v" \
    "$script_dir/top_with_fifo.v" \
    "$script_dir/uart_top_no_fifo.v" \
    "$script_dir/uart/rxuart.v" \
    "$script_dir/uart/txuart.v" \
    "$script_dir/memory/fifo-orig.v" \
    "$script_dir/memory/mem_dual.v" \
    "$script_dir/shake256/clog2.v" \
    "$script_dir/shake256/control_path.v" \
    "$script_dir/shake256/data_path.v" \
    "$script_dir/shake256/keccak_math.v" \
    "$script_dir/shake256/keccak_pkg.v" \
    "$script_dir/shake256/keccak_top.v" \
    "$script_dir/shake256/rc.v" \
    "$script_dir/shake256/state_ram.v" \
    "$script_dir/shake256/stateram_inference.v" \
    "$script_dir/shake256/transform.v" \
]

set vhdl_sources [list \
    "$script_dir/AES/src/AES_pkg.vhd" \
    "$script_dir/AES/src/AES_mul.vhd" \
    "$script_dir/AES/src/AES_map.vhd" \
    "$script_dir/AES/src/AES_invmap.vhd" \
    "$script_dir/AES/src/AES_Sbox.vhd" \
    "$script_dir/AES/src/AES_InvSbox.vhd" \
    "$script_dir/AES/src/AES_ShiftRows.vhd" \
    "$script_dir/AES/src/AES_InvShiftRows.vhd" \
    "$script_dir/AES/src/AES_MixColumn.vhd" \
    "$script_dir/AES/src/AES_MixColumns.vhd" \
    "$script_dir/AES/src/AES_InvMixColumn.vhd" \
    "$script_dir/AES/src/AES_InvMixColumns.vhd" \
    "$script_dir/AES/src/AES_SubBytes.vhd" \
    "$script_dir/AES/src/AES_InvSubBytes.vhd" \
    "$script_dir/AES/src/AES_KeyUpdate.vhd" \
    "$script_dir/AES/src/AES_Combined_Round.vhd" \
    "$script_dir/AES/src/AES_EncDec_Control.vhd" \
    "$script_dir/AES/src/AES_EncDec_Datapath.vhd" \
    "$script_dir/AES/src/AES_EncDec.vhd" \
]

add_files -norecurse $verilog_sources
add_files -norecurse $vhdl_sources

set_property file_type {VHDL} [get_files *.vhd]

add_files -fileset constrs_1 -norecurse "$script_dir/constraints/Basys-3-Master.xdc"

set_property top uart_top_no_fifo [current_fileset]
update_compile_order -fileset sources_1

launch_runs synth_1 -jobs 4
wait_on_run synth_1

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

set bitfile [get_property DIRECTORY [get_runs impl_1]]/uart_top_no_fifo.bit
puts "Bitstream generated: $bitfile"
