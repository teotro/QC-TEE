
proc ensure_lib { lib } { if ![file isdirectory $lib] { vlib $lib} }

set CUSTOM_DO_FILE  "wave.do"
set LIB_DIR         ./libs
set WORK_DIR        work

ensure_lib          $LIB_DIR
ensure_lib          [subst $LIB_DIR/$WORK_DIR/]
vmap work           [subst $LIB_DIR/$WORK_DIR/]

set TOP AEAD_TB

alias compile_vhdl_src {
	vcom -quiet -work work                            "../src_rtl/AES_pkg.vhd"
	vcom -quiet -work work                            "../src_rtl/AES_map.vhd"
	vcom -quiet -work work                            "../src_rtl/AES_invmap.vhd"
	vcom -quiet -work work                            "../src_rtl/AES_Sbox.vhd"
	vcom -quiet -work work                            "../src_rtl/AES_SubBytes.vhd"
	vcom -quiet -work work                            "../src_rtl/AES_mul.vhd"
	vcom -quiet -work work                            "../src_rtl/AES_MixColumn.vhd"
	vcom -quiet -work work                            "../src_rtl/AES_MixColumns.vhd"
	vcom -quiet -work work                            "../src_rtl/AES_ShiftRows.vhd"
	vcom -quiet -work work                            "../src_rtl/AES_KeyUpdate.vhd"
	vcom -quiet -work work                            "../src_rtl/AES_Round.vhd"
	vcom -quiet -work work                            "../src_rtl/AES_Enc_KOF_Datapath.vhd"
	vcom -quiet -work work                            "../src_rtl/AES_Enc_KOF_Control.vhd"
	vcom -quiet -work work                            "../src_rtl/AES_Enc_KOF.vhd"
	vcom -quiet -work work                            "../src_rtl/AEAD_pkg.vhd"
	vcom -quiet -work work                            "../src_rtl/GCM_Mult.vhd"
	vcom -quiet -work work                            "../src_rtl/CipherCore_Datapath.vhd"
	vcom -quiet -work work                            "../src_rtl/CipherCore_Control.vhd"
	vcom -quiet -work work                            "../src_rtl/CipherCore.vhd"
	vcom -quiet -work work                            "../src_rtl/fwft_fifo.vhd"
	vcom -quiet -work work                            "../src_rtl/PreProcessor.vhd"
	vcom -quiet -work work                            "../src_rtl/PostProcessor.vhd"
	vcom -quiet -work work                            "../src_rtl/AEAD.vhd"
	vcom -quiet -work work                            "../src_rtl/AEAD_Arch.vhd"
	vcom -quiet -work work                            "../src_rtl/AEAD_Wrapper.vhd"
}

alias compile_vhdl_tb {
	vcom -quiet -work work                            "../src_tb/std_logic_1164_additions.vhd"
	vcom -quiet -work work                            "../src_tb/AEAD_TB.vhd"
}


alias run_sim {
    set run_do_file [file isfile $CUSTOM_DO_FILE]
    if {$run_do_file == 1} {
        vsim -novopt -t ps -L work $TOP -do $CUSTOM_DO_FILE 
    } else {
        vsim -novopt -t ps -L work $TOP 
    }
    add wave -noupdate -group sim -radix hexadecimal $TOP/*
    add wave -noupdate -group core -radix hexadecimal $TOP/uut/*
    run 20 us
}

alias ld {
    set stall 0
    compile_vhdl_src    
    compile_vhdl_tb
    run_sim
}

alias ldv {
    set stall 0
    compile_vlog_src    
    compile_vlog_tb
    run_sim
}

alias h {
  echo "List Of Command Line Aliases"
  echo
  echo [subst "ld   -- Run Testbench (Vhdl: $TOP)"]
  echo
  echo [subst "ldv  -- Run Testbench (Vlog: $TOP)"]
  echo
}
h
