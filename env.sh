# U250 starter — shared environment.
# Source this once per shell before building or running anything:
#     source env.sh
#
# It sets up XRT (runtime) + Vitis/Vivado 2024.2 (tools), and exports the
# platform / part / log-root variables that every Makefile in this workspace
# reads. Nothing here is specific to a single example.

# --- Xilinx tools (Vitis + Vivado + XRT) ---------------------------------
# setup_vitis.sh sources XRT and puts v++, vivado, xsim, ... on PATH.
source /opt/tools/vitis2024.2/setup_vitis.sh >/dev/null 2>&1

# vitis_hls (used for HLS C-simulation / standalone synthesis) is NOT added to
# PATH by the vendor script, so add it here.
export XILINX_HLS=/opt/tools/vitis2024.2/Vitis_HLS/2024.2
export PATH="$XILINX_HLS/bin:$PATH"

# --- Board / platform ----------------------------------------------------
# Development platform that pairs with the "xilinx_u250_gen3x16_base_4" shell
# currently flashed on the card (check with: xrt-smi examine).
export PLATFORM=/opt/tools/vitis2024.2/platforms/xilinx_u250_gen3x16_xdma_4_1_202210_1/xilinx_u250_gen3x16_xdma_4_1_202210_1.xpfm
export PART=xcu250-figd2104-2L-e

# --- Where build logs and artifacts go -----------------------------------
# Each example writes to  $U250_LOG_ROOT/<build_name>_(rtl|hls)
export U250_LOG_ROOT=/scratch/aniketsadashiva/u250_logs

echo "[env] Vitis 2024.2 + XRT ready"
echo "[env] PLATFORM     = $PLATFORM"
echo "[env] PART         = $PART"
echo "[env] U250_LOG_ROOT= $U250_LOG_ROOT"
command -v v++   >/dev/null && echo "[env] v++       : $(command -v v++)"
command -v xsim  >/dev/null && echo "[env] xsim      : $(command -v xsim)"
command -v vitis_hls >/dev/null && echo "[env] vitis_hls : $(command -v vitis_hls)"
