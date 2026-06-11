// tb_sync_fifo.sv -------------------------------------------------------------
// Self-checking testbench for sync_fifo. Demonstrates the staples of an RTL
// testbench: a clock, reset, driving stimulus on the inactive clock edge,
// sampling outputs after the active edge, and checking against a reference
// model (here a SystemVerilog queue that mirrors what the FIFO should hold).
//
// Phases:
//   1. fill the FIFO and confirm 'full' asserts exactly at DEPTH
//   2. drain it and confirm values come out in order and 'empty' asserts
//   3. randomized interleaved writes/reads checked against the model
//
// Run with:  make sim   (from rtl/fifo/)
// ---------------------------------------------------------------------------
`timescale 1ns/1ps
`default_nettype none

module tb_sync_fifo;

  localparam int WIDTH = 32;
  localparam int DEPTH = 8;

  logic              clk = 0;
  logic              rst;
  logic              wr_en, rd_en;
  logic [WIDTH-1:0]  din, dout;
  logic              full, empty;

  always #5 clk = ~clk;   // 100 MHz

  sync_fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
    .clk(clk), .rst(rst),
    .wr_en(wr_en), .din(din), .full(full),
    .rd_en(rd_en), .dout(dout), .empty(empty)
  );

  int errors = 0, checks = 0;
  logic [WIDTH-1:0] model[$];   // reference: what the FIFO should contain

  task automatic expect_true(input bit cond, input string msg);
    checks++;
    if (!cond) begin $error("[%0t] %s", $time, msg); errors++; end
  endtask

  // Drive a write on the negedge; the transfer completes on the next posedge.
  task automatic push(input logic [WIDTH-1:0] v);
    @(negedge clk); wr_en = 1; din = v; rd_en = 0;
    @(posedge clk); #1 wr_en = 0;
    model.push_back(v);
  endtask

  // Drive a read; sample the registered dout after the posedge and compare.
  task automatic pop();
    logic [WIDTH-1:0] exp;
    @(negedge clk); rd_en = 1; wr_en = 0;
    @(posedge clk); #1 rd_en = 0;
    exp = model.pop_front();
    checks++;
    if (dout !== exp) begin
      $error("[%0t] pop got %0d, expected %0d", $time, dout, exp);
      errors++;
    end else
      $display("[%0t] PASS  pop = %0d", $time, dout);
  endtask

  initial begin
    // reset
    wr_en = 0; rd_en = 0; din = 0;
    rst = 1; repeat (3) @(posedge clk); #1 rst = 0;
    expect_true(empty && !full, "after reset FIFO must be empty and not full");

    // ---- Phase 1: fill completely ----
    $display("-- phase 1: fill --");
    for (int i = 0; i < DEPTH; i++) push(i*7 + 1);
    @(negedge clk);
    expect_true(full,  "FIFO should be full after DEPTH writes");
    expect_true(!empty,"full FIFO should not be empty");

    // ---- Phase 2: drain completely ----
    $display("-- phase 2: drain --");
    for (int i = 0; i < DEPTH; i++) pop();
    @(negedge clk);
    expect_true(empty, "FIFO should be empty after draining");
    expect_true(!full, "empty FIFO should not be full");

    // ---- Phase 3: randomized interleave ----
    $display("-- phase 3: random --");
    for (int i = 0; i < 200; i++) begin
      bit want_wr = $urandom_range(0,1);
      if (want_wr && !full)        push($urandom());
      else if (!want_wr && !empty) pop();
      else if (!full)              push($urandom());
      else                          pop();
    end
    // drain whatever remains
    while (model.size() > 0) pop();

    $display("--------------------------------------------------");
    if (errors == 0) $display("RESULT: PASS  (%0d checks)", checks);
    else             $display("RESULT: FAIL  (%0d errors / %0d checks)", errors, checks);
    $display("--------------------------------------------------");
    $finish;
  end

endmodule

`default_nettype wire
