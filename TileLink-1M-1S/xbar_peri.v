// xbar_peri.v - 24 MHz domain crossbar (single-slave pass-through)
`timescale 1ns/1ps

module xbar_peri #(
  parameter ADDR_WIDTH   = 32,
  parameter DATA_WIDTH   = 32,
  parameter MASK_WIDTH   = DATA_WIDTH/8,
  parameter SIZE_WIDTH   = 3,
  parameter SRC_WIDTH    = 2,
  parameter SINK_WIDTH   = 1,
  parameter OPCODE_WIDTH = 3,
  parameter PARAM_WIDTH  = 3
)(
  input clk,
  input reset,
  // Inputs from CDC adapter (TileLink Channel A & D in 24 MHz domain)
  input  a_valid,
  output reg a_ready,
  input  [OPCODE_WIDTH-1:0] a_opcode,
  input  [PARAM_WIDTH-1:0]  a_param,
  input  [SIZE_WIDTH-1:0]   a_size,
  input  [SRC_WIDTH-1:0]    a_source,
  input  [ADDR_WIDTH-1:0]   a_address,
  input  [MASK_WIDTH-1:0]   a_mask,
  input  [DATA_WIDTH-1:0]   a_data,

  output reg d_valid,
  input  d_ready,
  output reg [OPCODE_WIDTH-1:0] d_opcode,
  output reg [PARAM_WIDTH-1:0]  d_param,
  output reg [SIZE_WIDTH-1:0]   d_size,
  output reg [SRC_WIDTH-1:0]    d_source,
  output reg [SINK_WIDTH-1:0]   d_sink,
  output reg [DATA_WIDTH-1:0]   d_data,
  output reg d_error,

  // Slave-side TileLink interface (to actual slave or testbench)
  output reg a_valid_out,
  input  a_ready_out,
  output reg [OPCODE_WIDTH-1:0] a_opcode_out,
  output reg [PARAM_WIDTH-1:0]  a_param_out,
  output reg [SIZE_WIDTH-1:0]   a_size_out,
  output reg [SRC_WIDTH-1:0]    a_source_out,
  output reg [ADDR_WIDTH-1:0]   a_address_out,
  output reg [MASK_WIDTH-1:0]   a_mask_out,
  output reg [DATA_WIDTH-1:0]   a_data_out,

  input  d_valid_in,
  output reg d_ready_in,
  input  [OPCODE_WIDTH-1:0] d_opcode_in,
  input  [PARAM_WIDTH-1:0]  d_param_in,
  input  [SIZE_WIDTH-1:0]   d_size_in,
  input  [SRC_WIDTH-1:0]    d_source_in,
  input  [SINK_WIDTH-1:0]   d_sink_in,
  input  [DATA_WIDTH-1:0]   d_data_in,
  input  d_error_in
);

  // Pass-through assignments (single slave)
  assign a_valid_out   = a_valid;
  assign a_opcode_out  = a_opcode;
  assign a_param_out   = a_param;
  assign a_size_out    = a_size;
  assign a_source_out  = a_source;
  assign a_address_out = a_address;
  assign a_mask_out    = a_mask;
  assign a_data_out    = a_data;
  assign a_ready       = a_ready_out;

  assign d_valid       = d_valid_in;
  assign d_opcode      = d_opcode_in;
  assign d_param       = d_param_in;
  assign d_size        = d_size_in;
  assign d_source      = d_source_in;
  assign d_sink        = d_sink_in;
  assign d_data        = d_data_in;
  assign d_error       = d_error_in;
  assign d_ready_in    = d_ready;

  // Debug: Log handshake events on the slave side
  always @(posedge clk or posedge reset) begin
    if (!reset) begin
      if (a_valid && a_ready_out) begin
        $display("[%t] Slave accepted request (opcode=%0d, addr=0x%0h, source=%0d)",
                 $time, a_opcode, a_address, a_source);
      end
      if (d_valid_in && d_ready) begin
        $display("[%t] Slave response (opcode=%0d) forwarded to CDC (source=%0d, data=0x%0h)",
                 $time, d_opcode_in, d_source_in, d_data_in);
      end
    end
  end

endmodule

