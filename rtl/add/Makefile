# ===========================================================================
# RTL vadd kernel  ->  Alveo U250
#
# Flow:
#   make sim       fast SystemVerilog simulation of the adder core (xsim)
#   make xo        package src/hdl as a Vitis RTL kernel (.xo)   [Vivado]
#   make xclbin    link the .xo against the U250 platform        [v++]   (slow)
#   make host      compile the XRT host program                  [g++]
#   make run       run host + xclbin on the board
#   make all       xo + xclbin + host
#   make clean      remove local build artifacts
#
# This builds for real hardware (TARGET=hw). The xclbin link is the slow
# step (~1-2 h on the U250). 'make sim' is the fast inner loop for the RTL.
#
# Prereqs:  source ../../env.sh   (sets PLATFORM, PART, U250_LOG_ROOT, tools)
# Logs/artifacts: $(U250_LOG_ROOT)/add_rtl
# ===========================================================================

BUILD   := add
KERNEL  := krnl_vadd_rtl
TARGET  := hw

# --- from env.sh ----------------------------------------------------------
PLATFORM     ?= $(error PLATFORM not set -- run 'source ../../env.sh' first)
U250_LOG_ROOT ?= $(error U250_LOG_ROOT not set -- run 'source ../../env.sh' first)
DEVICE  := $(basename $(notdir $(PLATFORM)))

LOG_DIR   := $(U250_LOG_ROOT)/$(BUILD)_rtl
BUILD_DIR := build
XO        := $(BUILD_DIR)/$(KERNEL).$(TARGET).xo
XCLBIN    := $(BUILD_DIR)/$(KERNEL).$(TARGET).xclbin
HOST_EXE  := $(BUILD_DIR)/host

HDL := $(wildcard src/hdl/*.v src/hdl/*.sv)

# --- v++ link options -----------------------------------------------------
VPP_LINK_FLAGS := -l -t $(TARGET) --platform $(PLATFORM) \
                  --save-temps \
                  --temp_dir $(LOG_DIR)/_x \
                  --report_dir $(LOG_DIR)/reports \
                  --log_dir $(LOG_DIR)/logs \
                  --kernel_frequency 250

# --- host compile ---------------------------------------------------------
CXX       := g++
CXXFLAGS  := -std=c++17 -Wall -O2 -I$(XILINX_XRT)/include
LDFLAGS   := -L$(XILINX_XRT)/lib -lxrt_coreutil -pthread

.PHONY: all sim xo xclbin host run clean dirs help

help:
	@echo "Targets: sim | xo | xclbin | host | run | all   (builds for hardware)"

dirs:
	@mkdir -p $(LOG_DIR) $(BUILD_DIR)

# --- 1. RTL simulation of the adder core (fast, no board) -----------------
sim: dirs
	@echo ">> Simulating krnl_vadd_rtl_adder (log: $(LOG_DIR)/sim.log)"
	cd $(BUILD_DIR) && \
	  xvlog -sv ../src/hdl/krnl_vadd_rtl_adder.sv ../tb/tb_adder.sv 2>&1 | tee $(LOG_DIR)/sim.log && \
	  xelab tb_adder -s tb_adder_sim --timescale 1ns/1ps 2>&1 | tee -a $(LOG_DIR)/sim.log && \
	  xsim tb_adder_sim -runall 2>&1 | tee -a $(LOG_DIR)/sim.log
	@grep -q "RESULT: PASS" $(LOG_DIR)/sim.log && echo ">> SIM PASSED" || (echo ">> SIM FAILED"; exit 1)

# --- 2. Package RTL as a Vitis kernel object (.xo) ------------------------
xo: dirs $(XO)
$(XO): $(HDL) scripts/gen_xo.tcl scripts/package_kernel.tcl
	@echo ">> Packaging $(KERNEL).xo (log: $(LOG_DIR)/package_xo.log)"
	vivado -mode batch -source scripts/gen_xo.tcl -nojournal \
	  -log $(LOG_DIR)/package_xo.log \
	  -tclargs $(XO) $(KERNEL) $(TARGET) $(PLATFORM) $(DEVICE)

# --- 3. Link the kernel into an .xclbin (SLOW for TARGET=hw) ---------------
xclbin: dirs $(XCLBIN)
$(XCLBIN): $(XO)
	@echo ">> Linking $(XCLBIN) for TARGET=$(TARGET) (log: $(LOG_DIR)/link.log)"
	v++ $(VPP_LINK_FLAGS) $(XO) -o $(XCLBIN) 2>&1 | tee $(LOG_DIR)/link.log

# --- 4. Host program ------------------------------------------------------
host: dirs $(HOST_EXE)
$(HOST_EXE): host/host.cpp
	@echo ">> Compiling host"
	$(CXX) $(CXXFLAGS) host/host.cpp -o $(HOST_EXE) $(LDFLAGS)

# --- 5. Run on the board --------------------------------------------------
run: host xclbin
	@echo ">> Running on hardware (log: $(LOG_DIR)/run.log)"
	$(HOST_EXE) $(XCLBIN) 2>&1 | tee $(LOG_DIR)/run.log

all: xo xclbin host

clean:
	rm -rf $(BUILD_DIR) vivado*.log vivado*.jou .Xil *.str
