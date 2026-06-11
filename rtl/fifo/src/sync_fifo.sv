// sync_fifo.sv ---------------------------------------------------------------
// A textbook synchronous (single-clock) FIFO. This is one of the most common
// building blocks in digital design and a great vehicle for learning how to
// reason about pointers, full/empty flags, and corner cases.
//
//   - DEPTH entries of WIDTH-bit data (DEPTH must be a power of two)
//   - one clock, synchronous active-high reset
//   - write when (wr_en & ~full), read when (rd_en & ~empty)
//
// The classic trick: pointers are 1 bit wider than the address. When the
// pointers are equal the FIFO is empty; when they differ only in the MSB
// (same address, wrapped a different number of times) it is full.
// ---------------------------------------------------------------------------
`timescale 1ns/1ps
`default_nettype none

module sync_fifo #(
  parameter int WIDTH = 32,
  parameter int DEPTH = 16
) (
  input  wire             clk,
  input  wire             rst,        // synchronous, active high

  input  wire             wr_en,
  input  wire [WIDTH-1:0] din,
  output wire             full,

  input  wire             rd_en,
  output reg  [WIDTH-1:0] dout,
  output wire             empty
);

  localparam int AW = $clog2(DEPTH);

  reg [WIDTH-1:0] mem [0:DEPTH-1];
  reg [AW:0]      wr_ptr;   // one extra MSB for full/empty disambiguation
  reg [AW:0]      rd_ptr;

  wire do_wr = wr_en & ~full;
  wire do_rd = rd_en & ~empty;

  assign empty = (wr_ptr == rd_ptr);
  assign full  = (wr_ptr[AW] != rd_ptr[AW]) &&
                 (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]);

  // write port
  always @(posedge clk) begin
    if (rst)
      wr_ptr <= '0;
    else if (do_wr) begin
      mem[wr_ptr[AW-1:0]] <= din;
      wr_ptr <= wr_ptr + 1'b1;
    end
  end

  // read port (registered output)
  always @(posedge clk) begin
    if (rst)
      rd_ptr <= '0;
    else if (do_rd) begin
      dout   <= mem[rd_ptr[AW-1:0]];
      rd_ptr <= rd_ptr + 1'b1;
    end
  end

endmodule

`default_nettype wire
