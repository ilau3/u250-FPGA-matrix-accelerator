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
