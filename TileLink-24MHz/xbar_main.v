// xbar_main.sv - Single master configuration

`timescale 1ns/1ps

module xbar_main #(
  parameter ADDR_WIDTH   = 32,
  parameter DATA_WIDTH   = 32,
  parameter MASK_WIDTH   = DATA_WIDTH/8,
  parameter SIZE_WIDTH   = 3,
  parameter OPCODE_WIDTH = 3,
  parameter PARAM_WIDTH  = 3
)(
  input                  clk,
  input                  reset,
  // Master-side Channel A inputs
  input                            a_valid,
  output wire                      a_ready,
  input  [OPCODE_WIDTH-1:0]       a_opcode,
  input  [PARAM_WIDTH-1:0]        a_param,
  input  [SIZE_WIDTH-1:0]         a_size,
  input  	                  a_source,
  input  [ADDR_WIDTH-1:0]         a_address,
  input  [MASK_WIDTH-1:0]         a_mask,
  input  [DATA_WIDTH-1:0]         a_data,
  // Master-side Channel D outputs (to master)
  output reg                      d_valid,
  input                           d_ready,
  output reg [OPCODE_WIDTH-1:0]   d_opcode,
  output reg [PARAM_WIDTH-1:0]    d_param,
  output reg [SIZE_WIDTH-1:0]     d_size,
  output reg 		          d_source,
  output reg                      d_sink,
  output reg [DATA_WIDTH-1:0]     d_data,
  output reg                      d_error,
  // Outputs to CDC adapter (Channel A)
  output reg             a_valid_out,
  input                  a_ready_out,
  output reg [OPCODE_WIDTH-1:0] a_opcode_out,
  output reg [PARAM_WIDTH-1:0]  a_param_out,
  output reg [SIZE_WIDTH-1:0]   a_size_out,
  output reg 		        a_source_out,
  output reg [ADDR_WIDTH-1:0]   a_address_out,
  output reg [MASK_WIDTH-1:0]   a_mask_out,
  output reg [DATA_WIDTH-1:0]   a_data_out,
  // Inputs from CDC adapter (Channel D)
  input                  d_valid_in,
  output reg             d_ready_in,
  input  [OPCODE_WIDTH-1:0] d_opcode_in,
  input  [PARAM_WIDTH-1:0]  d_param_in,
  input  [SIZE_WIDTH-1:0]   d_size_in,
  input  		    d_source_in,
  input                     d_sink_in,
  input  [DATA_WIDTH-1:0]   d_data_in,
  input                  d_error_in
);

  // --- Channel A Forwarding ---

  always @* begin
    a_valid_out   = a_valid;
    a_opcode_out  = a_opcode;
    a_param_out   = a_param;
    a_size_out    = a_size;
    a_source_out  = a_source;  // Single master uses source 0
    a_address_out = a_address;
    a_mask_out    = a_mask;
    a_data_out    = a_data;
  end


  assign a_ready = a_ready_out;

  // --- Channel D Response Routing ---
  always @* begin
    d_valid   = d_valid_in;
    d_opcode  = d_opcode_in;
    d_param   = d_param_in;
    d_size    = d_size_in;
    d_source  = d_source_in;
    d_sink    = d_sink_in;
    d_data    = d_data_in;
    d_error   = d_error_in;
  end


  always d_ready_in = d_ready;

endmodule
