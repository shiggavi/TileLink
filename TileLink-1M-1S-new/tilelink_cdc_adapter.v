// tilelink_cdc_adapter.sv - Bridges 100 MHz and 24 MHz clock domains for TL-UL  
// Uses asynchronous FIFO for Channel A (request) and Channel D (response).
`timescale 1ns/1ps
`include "async_fifo.v"

module tilelink_cdc_adapter #(
  parameter ADDR_WIDTH   = 32,
  parameter DATA_WIDTH   = 32,
  parameter MASK_WIDTH   = DATA_WIDTH/8,
  parameter SIZE_WIDTH   = 3,
  parameter SRC_WIDTH    = 1,
  parameter SINK_WIDTH   = 1,
  parameter OPCODE_WIDTH = 3,
  parameter PARAM_WIDTH  = 3,
  parameter FIFO_DEPTH   = 8,

  parameter CH_A_WIDTH = 1 + OPCODE_WIDTH + PARAM_WIDTH + SIZE_WIDTH +
                        SRC_WIDTH + ADDR_WIDTH + MASK_WIDTH + DATA_WIDTH,
  parameter CH_D_WIDTH = 1 + OPCODE_WIDTH + PARAM_WIDTH + SIZE_WIDTH +
                        SRC_WIDTH + SINK_WIDTH + DATA_WIDTH + 1
)(
  // 100 MHz side
  input                   clk_in,
  input                   reset_in,
  // 24 MHz side
  input                   clk_out,
  input                   reset_out,

  // Channel A (request)
  input                   a_valid_in,
  output reg              a_ready_in,
  input  [OPCODE_WIDTH-1:0] a_opcode_in,
  input  [PARAM_WIDTH-1:0]  a_param_in,
  input  [SIZE_WIDTH-1:0]   a_size_in,
  input  	            a_source_in,
  input  [ADDR_WIDTH-1:0]   a_address_in,
  input  [MASK_WIDTH-1:0]   a_mask_in,
  input  [DATA_WIDTH-1:0]   a_data_in,

  output reg              a_valid_out,
  input                   a_ready_out,
  output reg [OPCODE_WIDTH-1:0] a_opcode_out,
  output reg [PARAM_WIDTH-1:0]  a_param_out,
  output reg [SIZE_WIDTH-1:0]   a_size_out,
  output reg 		        a_source_out,
  output reg [ADDR_WIDTH-1:0]   a_address_out,
  output reg [MASK_WIDTH-1:0]   a_mask_out,
  output reg [DATA_WIDTH-1:0]   a_data_out,

  // Channel D (response)
  input                   d_valid_in,
  output reg              d_ready_in,
  input  [OPCODE_WIDTH-1:0] d_opcode_in,
  input  [PARAM_WIDTH-1:0]  d_param_in,
  input  [SIZE_WIDTH-1:0]   d_size_in,
  input  		    d_source_in,
  input  		    d_sink_in,
  input  [DATA_WIDTH-1:0]   d_data_in,
  input                   d_error_in,

  output reg              d_valid_out,
  input                   d_ready_out,
  output reg [OPCODE_WIDTH-1:0] d_opcode_out,
  output reg [PARAM_WIDTH-1:0]  d_param_out,
  output reg [SIZE_WIDTH-1:0]   d_size_out,
  output reg 		        d_source_out,
  output reg                    d_sink_out,
  output reg [DATA_WIDTH-1:0]   d_data_out,
  output reg                 d_error_out
);

  // ----- Channel A FIFO (100 MHz → 24 MHz) -----
  wire [CH_A_WIDTH-1:0] fifo_a_wr_data, fifo_a_rd_data;
  wire                  fifo_a_wr_en, fifo_a_rd_en;
  wire                  fifo_a_full, fifo_a_empty;
   

  // Pack all Channel A signals into one wide vector for the FIFO
  assign fifo_a_wr_data = { a_valid_in,
                            a_opcode_in,
                            a_param_in,
                            a_size_in,
                            a_source_in,
                            a_address_in,
                            a_mask_in,
                            a_data_in };
  assign fifo_a_wr_en   = a_valid_in && !fifo_a_full;
  assign a_ready_in     = !fifo_a_full;

  // Instantiate asynchronous FIFO for Channel A
  async_fifo #(
    .DATA_WIDTH(CH_A_WIDTH),
    .DEPTH     (FIFO_DEPTH)
  ) fifo_a (
    .wr_clk (clk_in),
    .rd_clk (clk_out),
    .reset  (reset_in),
    .wr_en  (fifo_a_wr_en),
    .wr_data(fifo_a_wr_data),
    .full   (fifo_a_full),
    .rd_en  (fifo_a_rd_en),
    .rd_data(fifo_a_rd_data),
    .empty  (fifo_a_empty)
  );

  // On 24 MHz side, drive Channel A outputs from FIFO
  assign a_valid_out  = !fifo_a_empty;
  assign fifo_a_rd_en = a_valid_out && a_ready_out;

  // Unpack FIFO A read data (order matches packing above)
  assign a_opcode_out  = fifo_a_rd_data[CH_A_WIDTH-1 -: OPCODE_WIDTH];
  assign a_param_out   = fifo_a_rd_data[CH_A_WIDTH-OPCODE_WIDTH-1 -: PARAM_WIDTH];
  assign a_size_out    = fifo_a_rd_data[CH_A_WIDTH-OPCODE_WIDTH-PARAM_WIDTH-1 -: SIZE_WIDTH];
  assign a_source_out  = fifo_a_rd_data[CH_A_WIDTH-OPCODE_WIDTH-PARAM_WIDTH-SIZE_WIDTH-1 -: SRC_WIDTH];
  assign a_address_out = fifo_a_rd_data[CH_A_WIDTH-OPCODE_WIDTH-PARAM_WIDTH-SIZE_WIDTH-SRC_WIDTH-1 -: ADDR_WIDTH];
  assign a_mask_out    = fifo_a_rd_data[CH_A_WIDTH-OPCODE_WIDTH-PARAM_WIDTH-SIZE_WIDTH-SRC_WIDTH-ADDR_WIDTH-1 -: MASK_WIDTH];
  assign a_data_out    = fifo_a_rd_data[DATA_WIDTH-1:0];

  // ----- Channel D FIFO (24 MHz → 100 MHz) -----
  wire [CH_D_WIDTH-1:0] fifo_d_wr_data, fifo_d_rd_data;
  wire                  fifo_d_wr_en, fifo_d_rd_en;
  wire                  fifo_d_full, fifo_d_empty;


  assign fifo_d_wr_data = { d_valid_in,
                            d_opcode_in,
                            d_param_in,
                            d_size_in,
                            d_source_in,
                            d_sink_in,
                            d_data_in,
                            d_error_in };
  assign fifo_d_wr_en   = d_valid_in && !fifo_d_full;
  assign d_ready_in     = !fifo_d_full;

  async_fifo #(
    .DATA_WIDTH(CH_D_WIDTH),
    .DEPTH     (FIFO_DEPTH)
  ) fifo_d (
    .wr_clk (clk_out),
    .rd_clk (clk_in),
    .reset  (reset_out),
    .wr_en  (fifo_d_wr_en),
    .wr_data(fifo_d_wr_data),
    .full   (fifo_d_full),
    .rd_en  (fifo_d_rd_en),
    .rd_data(fifo_d_rd_data),
    .empty  (fifo_d_empty)
  );


  assign d_valid_out = !fifo_d_empty;
  assign fifo_d_rd_en = d_valid_out && d_ready_out;
  // Unpack FIFO D data
  assign d_opcode_out = fifo_d_rd_data[CH_D_WIDTH-1 -: OPCODE_WIDTH];
  assign d_param_out  = fifo_d_rd_data[CH_D_WIDTH-OPCODE_WIDTH-1 -: PARAM_WIDTH];
  assign d_size_out   = fifo_d_rd_data[CH_D_WIDTH-OPCODE_WIDTH-PARAM_WIDTH-1 -: SIZE_WIDTH];
  assign d_source_out = fifo_d_rd_data[CH_D_WIDTH-OPCODE_WIDTH-PARAM_WIDTH-SIZE_WIDTH-1 -: SRC_WIDTH];
  assign d_sink_out   = fifo_d_rd_data[CH_D_WIDTH-OPCODE_WIDTH-PARAM_WIDTH-SIZE_WIDTH-SRC_WIDTH-1 -: SINK_WIDTH];
  assign d_data_out   = fifo_d_rd_data[DATA_WIDTH-1:0];
  assign d_error_out  = fifo_d_rd_data[0]; // LSB is error flag

  // ------------------- Debug: Monitor FIFO Transfers -------------------
  // Channel A (100MHz side write)
  always @(posedge clk_in or posedge reset_in) begin
    if (!reset_in) begin
      if (fifo_a_wr_en) begin
        $display("[%t] CDC: Captured A request (opcode=%0d, addr=0x%0h, source=%0d) in async FIFO",
                 $time, a_opcode_in, a_address_in, a_source_in);
      end
    end
  end
  // Channel A (24MHz side read)
  always @(posedge clk_out or posedge reset_out) begin
    if (!reset_out) begin
      if (fifo_a_rd_en) begin
        $display("[%t] CDC: Sent A request (opcode=%0d, addr=0x%0h, source=%0d) to 24MHz domain",
                 $time, a_opcode_out, a_address_out, a_source_out);
      end
    end
  end
  // Channel D (24MHz side write)
  always @(posedge clk_out or posedge reset_out) begin
    if (!reset_out) begin
      if (fifo_d_wr_en) begin
        $display("[%t] CDC: Captured D response (opcode=%0d, source=%0d, data=0x%0h) in async FIFO",
                 $time, d_opcode_in, d_source_in, d_data_in);
      end
    end
  end
  // Channel D (100MHz side read)
  always @(posedge clk_in or posedge reset_in) begin
    if (!reset_in) begin
      if (fifo_d_rd_en) begin
        $display("[%t] CDC: Sent D response (opcode=%0d, source=%0d, data=0x%0h) to 100MHz domain",
                 $time, d_opcode_out, d_source_out, d_data_out);
      end
    end
  end

endmodule
