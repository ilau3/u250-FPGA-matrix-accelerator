// tb_adder.sv ---------------------------------------------------------------
// A small, self-checking testbench for the compute core of the vadd kernel,
// krnl_vadd_rtl_adder: drive inputs, wait a step, check the output, print
// PASS/FAIL.
//
// The adder is purely combinational with a simple AXI-stream-style handshake:
//   - two input channels  s_tdata[0], s_tdata[1]  qualified by s_tvalid
//   - one output          m_tdata = s_tdata[0] + s_tdata[1], valid = &s_tvalid
//
// Run it with:  make sim         (from rtl/add/)
// ---------------------------------------------------------------------------
`timescale 1ns/1ps
`default_nettype none

module tb_adder;

  localparam int C_DATA_WIDTH   = 32;
  localparam int C_NUM_CHANNELS = 2;

  // DUT connections
  logic                                            aclk = 0;
  logic                                            areset = 0;
  logic [C_NUM_CHANNELS-1:0]                       s_tvalid;
  logic [C_NUM_CHANNELS-1:0][C_DATA_WIDTH-1:0]     s_tdata;
  logic [C_NUM_CHANNELS-1:0]                       s_tready;
  logic                                            m_tvalid;
  logic [C_DATA_WIDTH-1:0]                          m_tdata;
  logic                                            m_tready;

  // 100 MHz clock (the core is combinational, but a clock keeps the testbench
  // tidy and matches how the block is used inside the kernel).
  always #5 aclk = ~aclk;

  // Device under test
  krnl_vadd_rtl_adder #(
    .C_DATA_WIDTH   (C_DATA_WIDTH),
    .C_NUM_CHANNELS (C_NUM_CHANNELS)
  ) dut (
    .aclk     (aclk),
    .areset   (areset),
    .s_tvalid (s_tvalid),
    .s_tdata  (s_tdata),
    .s_tready (s_tready),
    .m_tvalid (m_tvalid),
    .m_tdata  (m_tdata),
    .m_tready (m_tready)
  );

  int errors = 0;
  int checks = 0;

  // Apply one pair of operands and check the combinational sum.
  task automatic check_add(input logic [C_DATA_WIDTH-1:0] a,
                           input logic [C_DATA_WIDTH-1:0] b);
    logic [C_DATA_WIDTH-1:0] expected;
    begin
      s_tdata[0] = a;
      s_tdata[1] = b;
      s_tvalid   = 2'b11;   // both inputs valid
      m_tready   = 1'b1;    // downstream ready to accept
      #1;                   // let the combinational logic settle
      expected = a + b;
      checks++;
      if (m_tvalid !== 1'b1) begin
        $error("[%0t] m_tvalid should be high when both inputs are valid", $time);
        errors++;
      end else if (m_tdata !== expected) begin
        $error("[%0t] %0d + %0d => got %0d, expected %0d",
               $time, a, b, m_tdata, expected);
        errors++;
      end else begin
        $display("[%0t] PASS  %0d + %0d = %0d", $time, a, b, m_tdata);
      end
      @(posedge aclk);
    end
  endtask

  initial begin
    // reset / init
    s_tvalid = '0;
    s_tdata  = '0;
    m_tready = 1'b0;
    areset   = 1'b1;
    repeat (3) @(posedge aclk);
    areset   = 1'b0;

    // directed cases
    check_add(32'd0,        32'd0);
    check_add(32'd1,        32'd2);
    check_add(32'd100,      32'd23);
    check_add(32'hFFFF_FFFF,32'd1);     // wraps to 0 (unsigned, no overflow flag)
    check_add(32'h1234_5678,32'h0000_1111);

    // a few randomized cases
    for (int i = 0; i < 20; i++) begin
      check_add($urandom(), $urandom());
    end

    // de-assert valid: output must not claim valid
    s_tvalid = 2'b01;
    #1;
    checks++;
    if (m_tvalid !== 1'b0) begin
      $error("[%0t] m_tvalid should be low when only one input is valid", $time);
      errors++;
    end else begin
      $display("[%0t] PASS  m_tvalid low when inputs incomplete", $time);
    end

    $display("--------------------------------------------------");
    if (errors == 0)
      $display("RESULT: PASS  (%0d checks)", checks);
    else
      $display("RESULT: FAIL  (%0d errors / %0d checks)", errors, checks);
    $display("--------------------------------------------------");
    $finish;
  end

endmodule

`default_nettype wire
