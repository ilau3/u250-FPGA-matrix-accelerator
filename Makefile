# ===========================================================================
# u250_starter -- top-level convenience dispatcher.
#
# Every example also has its own Makefile; this just lets you drive them from
# one place. Always source the environment first:
#
#     source env.sh
#
# Fast checks (seconds, no board):
#     make sims          run all four simulations (RTL xsim + HLS C-sim)
#
# Per-example pass-through (build/run on hardware -- the xclbin steps are slow):
#     make rtl-add       cd rtl/add  && make all
#     make rtl-add-run   cd rtl/add  && make run
#     make hls-add       cd hls/add  && make all
#     make hls-add-run   cd hls/add  && make run
#     ... and -fifo variants
# ===========================================================================

.PHONY: sims \
        rtl-add-sim rtl-fifo-sim hls-add-csim hls-fifo-csim \
        rtl-add rtl-add-run rtl-fifo \
        hls-add hls-add-run hls-fifo hls-fifo-run \
        clean help

help:
	@sed -n '1,30p' Makefile

# ---- fast simulations ----
rtl-add-sim:
	$(MAKE) -C rtl/add sim
rtl-fifo-sim:
	$(MAKE) -C rtl/fifo sim
hls-add-csim:
	$(MAKE) -C hls/add csim
hls-fifo-csim:
	$(MAKE) -C hls/fifo csim

sims: rtl-add-sim rtl-fifo-sim hls-add-csim hls-fifo-csim
	@echo ">> all simulations done"

# ---- RTL hardware ----
rtl-add:
	$(MAKE) -C rtl/add all
rtl-add-run:
	$(MAKE) -C rtl/add run
rtl-fifo:        # FIFO is sim-only
	$(MAKE) -C rtl/fifo sim

# ---- HLS hardware ----
hls-add:
	$(MAKE) -C hls/add all
hls-add-run:
	$(MAKE) -C hls/add run
hls-fifo:
	$(MAKE) -C hls/fifo all
hls-fifo-run:
	$(MAKE) -C hls/fifo run

clean:
	-$(MAKE) -C rtl/add clean
	-$(MAKE) -C rtl/fifo clean
	-$(MAKE) -C hls/add clean
	-$(MAKE) -C hls/fifo clean

# ===========================================================================
# Isolated SV unit test -- simulate ANY module(s)+testbench in xsim.
# No board, no Vitis, no xclbin: just xvlog -> xelab -> xsim, in seconds.
#
#   make utest SRC="<sv files incl. its testbench>" TB=<testbench_top_module>
#   make uwave SRC="..." TB=...        # same, but dump a waveform (dump.vcd)
#
# examples:
#   make utest SRC="rtl/add/src/hdl/krnl_vadd_rtl_adder.sv rtl/add/tb/tb_adder.sv" TB=tb_adder
#   make utest SRC="rtl/fifo/src/sync_fifo.sv rtl/fifo/tb/tb_sync_fifo.sv"          TB=tb_sync_fifo
# A self-checking testbench prints "RESULT: PASS"; this reports ">> UTEST PASSED".
# ===========================================================================
.PHONY: utest uwave
UTEST_DIR := $(U250_LOG_ROOT)/utest

utest:
	@test -n '$(U250_LOG_ROOT)' || { echo '>> U250_LOG_ROOT not set -- run: source env.sh   (utest writes to $$U250_LOG_ROOT/utest in scratch)'; exit 2; }
	@test -n '$(SRC)' || { echo 'usage: make utest SRC="dut.sv tb.sv" TB=tb_top'; exit 2; }
	@test -n '$(TB)'  || { echo 'usage: make utest SRC="dut.sv tb.sv" TB=tb_top'; exit 2; }
	@mkdir -p $(UTEST_DIR)
	@echo ">> utest: $(TB)  (log: $(UTEST_DIR)/utest.log)"
	cd $(UTEST_DIR) && \
	  xvlog -sv $(abspath $(SRC)) 2>&1 | tee utest.log && \
	  xelab $(TB) -s $(TB)_sim --timescale 1ns/1ps 2>&1 | tee -a utest.log && \
	  xsim $(TB)_sim -runall 2>&1 | tee -a utest.log
	@grep -qE 'RESULT: PASS|TEST PASSED' $(UTEST_DIR)/utest.log && echo ">> UTEST PASSED" || { echo ">> UTEST FAILED"; exit 1; }

uwave:
	@test -n '$(U250_LOG_ROOT)' || { echo '>> U250_LOG_ROOT not set -- run: source env.sh   (uwave writes to $$U250_LOG_ROOT/utest in scratch)'; exit 2; }
	@test -n '$(SRC)' || { echo 'usage: make uwave SRC="dut.sv tb.sv" TB=tb_top'; exit 2; }
	@test -n '$(TB)'  || { echo 'usage: make uwave SRC="dut.sv tb.sv" TB=tb_top'; exit 2; }
	@mkdir -p $(UTEST_DIR)
	cd $(UTEST_DIR) && \
	  xvlog -sv $(abspath $(SRC)) 2>&1 | tee utest.log && \
	  xelab $(TB) -s $(TB)_sim --debug all --timescale 1ns/1ps 2>&1 | tee -a utest.log && \
	  printf 'open_vcd\nlog_vcd /*\nrun all\nclose_vcd\nexit\n' > uwave.tcl && \
	  xsim $(TB)_sim -tclbatch uwave.tcl 2>&1 | tee -a utest.log
	@echo ">> waveform: $(UTEST_DIR)/dump.vcd  (open with: gtkwave $(UTEST_DIR)/dump.vcd)"
