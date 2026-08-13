VIVADO     ?= vivado
TCL_SCRIPT  = hardware/create_project.tcl
PROJ_DIR    = vivado_proj

PYTHON      ?= python3
SW_DIR       = software

# Serial port settings - override on the command line, e.g.:
#   make loopback PORT=/dev/ttyUSB0 BAUD=115200
PORT        ?= /dev/ttyUSB0
BAUD        ?= 115200

.PHONY: all bitstream loopback clean

all: bitstream

bitstream:
	$(VIVADO) -mode batch -source $(TCL_SCRIPT) -nojournal -nolog

# NOTE: Before running 'make loopback' you must:
#   1. Run 'make bitstream' to generate the bitstream
#   2. Program the FPGA with the generated bitstream
#      (vivado_proj/qc_tee.runs/impl_1/uart_top_no_fifo.bit)
#   Once the FPGA is programmed you can run the UART loopback test.
loopback:
	$(PYTHON) $(SW_DIR)/uart_loopback_test.py --port $(PORT) --baud $(BAUD)

clean:
	rm -rf $(PROJ_DIR)
