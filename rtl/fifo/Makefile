# ===========================================================================
# RTL FIFO -- simulation-only learning example (no board, no bitstream).
#
#   make sim     compile + run the self-checking testbench in xsim
#   make wave    same, but dump a waveform you can open in the Vivado viewer
#   make clean
#
# A FIFO is a building block, not a standalone accelerator, so there is no
# xclbin here -- the point is to get comfortable writing and simulating
# SystemVerilog with a testbench. Logs go to $(U250_LOG_ROOT)/fifo_rtl.
#
# Prereqs:  source ../../env.sh
# ===========================================================================

BUILD := fifo
U250_LOG_ROOT ?= $(error U250_LOG_ROOT not set -- run 'source ../../env.sh' first)
LOG_DIR   := $(U250_LOG_ROOT)/$(BUILD)_rtl
BUILD_DIR := build

SRC := src/sync_fifo.sv tb/tb_sync_fifo.sv

.PHONY: sim wave clean dirs
dirs:
	@mkdir -p $(LOG_DIR) $(BUILD_DIR)

sim: dirs
	@echo ">> Simulating sync_fifo (log: $(LOG_DIR)/sim.log)"
	cd $(BUILD_DIR) && \
	  xvlog -sv ../src/sync_fifo.sv ../tb/tb_sync_fifo.sv 2>&1 | tee $(LOG_DIR)/sim.log && \
	  xelab tb_sync_fifo -s tb_fifo_sim --timescale 1ns/1ps 2>&1 | tee -a $(LOG_DIR)/sim.log && \
	  xsim tb_fifo_sim -runall 2>&1 | tee -a $(LOG_DIR)/sim.log
	@grep -q "RESULT: PASS" $(LOG_DIR)/sim.log && echo ">> SIM PASSED" || (echo ">> SIM FAILED"; exit 1)

# Dump waveforms: opens with  xsim --gui $(BUILD_DIR)/tb_fifo_sim.wdb
wave: dirs
	cd $(BUILD_DIR) && \
	  xvlog -sv ../src/sync_fifo.sv ../tb/tb_sync_fifo.sv 2>&1 | tee $(LOG_DIR)/sim.log && \
	  xelab tb_sync_fifo -s tb_fifo_sim --debug all --timescale 1ns/1ps 2>&1 | tee -a $(LOG_DIR)/sim.log && \
	  echo "open_vcd; log_vcd /*; run all; close_vcd; exit" > xsim_wave.tcl && \
	  xsim tb_fifo_sim -tclbatch xsim_wave.tcl 2>&1 | tee -a $(LOG_DIR)/sim.log

clean:
	rm -rf $(BUILD_DIR) xsim.dir *.log *.jou *.pb .Xil
