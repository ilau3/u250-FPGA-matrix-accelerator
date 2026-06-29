# ===========================================================================
# HLS matmul kernel  ->  Alveo U250
#
#   make csim      compile + run the C testbench (plain g++, milliseconds)
#   make xo        synthesize the kernel to a .xo            [v++ -c]  (slow)
#   make xclbin    link the .xo against the U250 platform    [v++ -l]  (slow)
#   make host      compile the XRT host program              [g++]
#   make run       run host + xclbin on the board
#   make all       xo + xclbin + host
#   make clean
#
# Builds for real hardware. 'make csim' is the fast inner loop for the C model.
#
# Prereqs:  source ../../env.sh
# Logs/artifacts: $(U250_LOG_ROOT)/add_hls
# ===========================================================================

BUILD  := matmul
KERNEL := matmul
TARGET := hw

PLATFORM      ?= $(error PLATFORM not set -- run 'source ../../env.sh' first)
U250_LOG_ROOT ?= $(error U250_LOG_ROOT not set -- run 'source ../../env.sh' first)

LOG_DIR   := $(U250_LOG_ROOT)/$(BUILD)_hls
BUILD_DIR := build
XO        := $(BUILD_DIR)/$(KERNEL).$(TARGET).xo
XCLBIN    := $(BUILD_DIR)/$(KERNEL).$(TARGET).xclbin
HOST_EXE  := $(BUILD_DIR)/host

VPP_COMMON := -t $(TARGET) --platform $(PLATFORM) \
              --temp_dir $(LOG_DIR)/_x \
              --report_dir $(LOG_DIR)/reports \
              --log_dir $(LOG_DIR)/logs \
              --save-temps

CXX      := g++
CXXFLAGS := -std=c++17 -Wall -O2 -I$(XILINX_XRT)/include
LDFLAGS  := -L$(XILINX_XRT)/lib -lxrt_coreutil -pthread

.PHONY: all csim xo xclbin host run clean dirs help
help:
	@echo "Targets: csim | xo | xclbin | host | run | all   (builds for hardware)"

dirs:
	@mkdir -p $(LOG_DIR) $(BUILD_DIR)

# --- C simulation (no FPGA, no synthesis) ---------------------------------
csim: dirs
	@echo ">> C-sim (log: $(LOG_DIR)/csim.log)"
	$(CXX) -std=c++17 -O2 src/matmul.cpp tb/matmul_tb.cpp -o $(BUILD_DIR)/matmul_csim
	@$(BUILD_DIR)/matmul_csim 2>&1 | tee $(LOG_DIR)/csim.log
	@grep -q "RESULT: PASS" $(LOG_DIR)/csim.log && echo ">> CSIM PASSED" || (echo ">> CSIM FAILED"; exit 1)

# --- Synthesize kernel to .xo (slow) --------------------------------------
xo: dirs $(XO)
$(XO): src/matmul.cpp
	@echo ">> v++ -c $(KERNEL) (log: $(LOG_DIR)/compile.log)"
	v++ -c $(VPP_COMMON) -k $(KERNEL) src/matmul.cpp -o $(XO) 2>&1 | tee $(LOG_DIR)/compile.log

# --- Link to .xclbin (slow) -----------------------------------------------
xclbin: dirs $(XCLBIN)
$(XCLBIN): $(XO)
	@echo ">> v++ -l (log: $(LOG_DIR)/link.log)"
	v++ -l $(VPP_COMMON) $(XO) -o $(XCLBIN) 2>&1 | tee $(LOG_DIR)/link.log

# --- Host -----------------------------------------------------------------
host: dirs $(HOST_EXE)
$(HOST_EXE): host/host.cpp
	$(CXX) $(CXXFLAGS) host/host.cpp -o $(HOST_EXE) $(LDFLAGS)

# --- Run on the board -----------------------------------------------------
run: host xclbin
	@echo ">> Running on hardware (log: $(LOG_DIR)/run.log)"
	$(HOST_EXE) $(XCLBIN) 2>&1 | tee $(LOG_DIR)/run.log

all: xo xclbin host

clean:
	rm -rf $(BUILD_DIR) v++*.log .Xil
