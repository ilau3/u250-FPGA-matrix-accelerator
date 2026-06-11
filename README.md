# U250 Starter Code

Starter code for building and running accelerators on the **Alveo U250** FPGA
card. It covers the **two ways** you can describe hardware for the card:

- **RTL** — you write the hardware directly in SystemVerilog/Verilog.
- **HLS** — you write C++ and the Vitis HLS compiler generates the hardware.

Each side has **two examples**: a vector **add** and a **fifo**.

```
u250_starter/
├── env.sh                  # source this first (tools + platform + log paths)
├── Makefile                # convenience dispatcher (optional)
├── rtl/
│   ├── add/                # vadd RTL kernel  -> runs on hardware
│   └── fifo/               # synchronous FIFO -> simulation-only learning
├── hls/
│   ├── add/                # vadd HLS kernel       -> runs on hardware
│   └── fifo/               # hls::stream FIFO kernel -> runs on hardware
└── reference_Vitis_Accel_Examples -> Xilinx's official example repo
```

---

## 0. The mental model (read this once)

An FPGA accelerator has two halves:

1. A **kernel** — the hardware that does the work. It lives on the card and is
   compiled into a bitstream file called an **`.xclbin`**.
2. A **host program** — ordinary C++ running on the CPU. It uses the **XRT**
   library to load the `.xclbin`, copy data to/from the card's DDR memory, set
   kernel arguments, and start the kernel.

The host doesn't care whether the kernel was written in RTL or HLS — the
`.xclbin` looks the same to it. That's why the host code in `rtl/add` and
`hls/add` is nearly identical.

Building the `.xclbin` for **real hardware is slow** (roughly **1–2 hours** —
it runs full synthesis, placement, and routing on the whole chip). So the
workflow is always: **simulate fast first, build the bitstream once it's
correct.**

---

## 1. One-time setup

From this directory, in every new shell:

```bash
source env.sh
```

This sources Vitis/Vivado 2024.2 + XRT and exports:

| Variable        | Meaning                                             |
|-----------------|-----------------------------------------------------|
| `PLATFORM`      | the U250 development platform (`.xpfm`)             |
| `PART`          | the FPGA part (`xcu250-figd2104-2L-e`)              |
| `U250_LOG_ROOT` | where all logs/artifacts go: `/scratch/aniketsadashiva/u250_logs` |

Check the card is alive any time with:

```bash
xrt-smi examine          # should list xilinx_u250_gen3x16_base_4, Device Ready: Yes
```

**Logs and build artifacts** for each example land in
`$U250_LOG_ROOT/<example>_<flow>/`, e.g.:

```
/scratch/aniketsadashiva/u250_logs/add_rtl/    <- rtl/add  build + run logs
/scratch/aniketsadashiva/u250_logs/add_hls/    <- hls/add  build + run logs
/scratch/aniketsadashiva/u250_logs/fifo_rtl/   <- rtl/fifo sim logs
/scratch/aniketsadashiva/u250_logs/fifo_hls/   <- hls/fifo build + run logs
```

---

## 2. Start here: simulate everything (seconds, no board)

```bash
source env.sh
make sims
```

This runs all four self-checking simulations and prints `RESULT: PASS` for
each. Nothing touches the FPGA yet — this is the fast feedback loop you'll live
in while developing.

You can also run them one at a time:

```bash
make -C rtl/add  sim      # SystemVerilog testbench of the adder core (xsim)
make -C rtl/fifo sim      # SystemVerilog testbench of the FIFO       (xsim)
make -C hls/add  csim     # C-simulation of the HLS vadd kernel       (g++)
make -C hls/fifo csim     # C-simulation of the HLS stream FIFO       (g++)
```

---

## 3. The RTL flow (SystemVerilog → hardware)

Go look at `rtl/add/`. The kernel is built from these SystemVerilog modules
(adapted from Xilinx's official `rtl_vadd` example, so it's known-good):

| File                                | Role                                          |
|-------------------------------------|-----------------------------------------------|
| `krnl_vadd_rtl.v`                   | top wrapper (port list)                       |
| `krnl_vadd_rtl_int.sv`              | wires the pieces together                     |
| `krnl_vadd_rtl_control_s_axi.v`     | AXI4-Lite control regs (start/done + args)    |
| `krnl_vadd_rtl_axi_read_master.sv`  | reads operands from DDR                        |
| `krnl_vadd_rtl_axi_write_master.sv` | writes results to DDR                          |
| `krnl_vadd_rtl_adder.sv`            | **the actual compute** (a + b)                |
| `krnl_vadd_rtl_counter.sv`          | small helper                                   |

Start by reading `krnl_vadd_rtl_adder.sv` and its testbench
`tb/tb_adder.sv` — that's the "very basic SystemVerilog + testbench" part.

```bash
cd rtl/add
make sim        # simulate the adder core in xsim  (fast)

# Build for the board (SLOW, ~1-2h):
make xo         # Vivado packages the RTL into a Vitis kernel (.xo)
make xclbin     # v++ links the .xo against the U250 platform -> .xclbin
make host       # g++ builds the XRT host program
make run        # loads the .xclbin and runs c = a + b on the card

# or just:  make all   (xo + xclbin + host), then  make run
```

The **FIFO** example (`rtl/fifo/`) is simulation-only — a FIFO is a building
block, not a standalone accelerator, so it's the perfect vehicle for practicing
SystemVerilog and testbenches without waiting on a 2-hour build:

```bash
cd rtl/fifo
make sim        # fill / drain / random checks against a reference model
make wave       # same, but dumps a waveform for the Vivado viewer
```

---

## 4. The HLS flow (C++ → hardware)

Go look at `hls/add/src/vadd.cpp`. It's just a `for` loop with `#pragma HLS`
annotations describing how the function arguments become AXI ports. Compare it
to the pile of `.sv` files in `rtl/add/` — HLS generates all of that for you.

```bash
cd hls/add
make csim       # compile + run the C testbench with g++  (milliseconds)

# Build for the board (SLOW, ~1-2h):
make xo         # v++ -c synthesizes vadd.cpp to a kernel (.xo)
make xclbin     # v++ -l links it against the U250 platform -> .xclbin
make host       # g++ builds the XRT host
make run        # runs on the card
```

The HLS **FIFO** example (`hls/fifo/`) shows the idiomatic use of a FIFO in
HLS: an `hls::stream` connecting two `DATAFLOW` stages (a producer and a
consumer that overlap in time). Same `csim / xo / xclbin / host / run` targets.

---

## 5. Suggested path through the code

1. `make sims` — see all four pass.
2. Read `rtl/add/src/hdl/krnl_vadd_rtl_adder.sv` + `tb/tb_adder.sv`. Tweak the
   testbench, re-run `make -C rtl/add sim`.
3. Read `rtl/fifo/src/sync_fifo.sv` + its testbench. Try changing `DEPTH`.
4. Read `hls/add/src/vadd.cpp`. Notice how little code produces the same kernel.
5. Build **one** kernel end-to-end on hardware (start with `hls/add`, it's the
   simplest): `cd hls/add && make all && make run`. Expect ~1–2 h for the build.
6. Build `rtl/add` on hardware the same way and compare.
7. Browse `reference_Vitis_Accel_Examples/` for dozens more official examples
   (`hello_world/`, `rtl_kernels/`, `performance/`, ...).

---

## 6. Troubleshooting

- **`PLATFORM not set`** → you forgot `source env.sh` in this shell.
- **`make run` can't find the device / permission denied** → check
  `xrt-smi examine` shows the card "Device Ready: Yes".
- **xclbin build seems stuck** → it isn't; place-and-route genuinely takes
  ~1–2 h. Watch progress in `$U250_LOG_ROOT/<example>_<flow>/link.log`.
- **Rebuild from scratch** → `make clean` in the example dir (this does *not*
  delete the logs under `$U250_LOG_ROOT`).
