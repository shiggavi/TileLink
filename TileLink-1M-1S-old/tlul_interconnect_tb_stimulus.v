`timescale 1ns/1ps

// Parameter Declarations
parameter DATA_WIDTH   = 32;
parameter ADDR_WIDTH   = 32;
parameter MASK_WIDTH   = DATA_WIDTH/8;
parameter SIZE_WIDTH   = 3;
parameter SRC_WIDTH    = 1;
parameter SINK_WIDTH   = 1;
parameter OPCODE_WIDTH = 3;
parameter PARAM_WIDTH  = 3;
parameter FIFO_DEPTH   = 8;

module tlul_interconnect_tb(
  // Testbench-driven signals (function as DUT inputs)
  output reg                 clk_100,
  output reg                 clk_24,
  output reg                 reset,
  output reg                 master_a_valid,
  output reg [OPCODE_WIDTH-1:0] master_a_opcode,
  output reg [PARAM_WIDTH-1:0]  master_a_param,
  output reg [SIZE_WIDTH-1:0]   master_a_size,
  output reg 		        master_a_source,
  output reg [ADDR_WIDTH-1:0]   master_a_address,
  output reg [MASK_WIDTH-1:0]   master_a_mask,
  output reg [DATA_WIDTH-1:0]   master_a_data,
  output reg                 master_d_ready,
  output reg                 slave_a_valid,
  output reg [OPCODE_WIDTH-1:0] slave_a_opcode,
  output reg [PARAM_WIDTH-1:0]  slave_a_param,
  output reg [SIZE_WIDTH-1:0]   slave_a_size,
  output reg 		        slave_a_source,
  output reg [ADDR_WIDTH-1:0] slave_a_address,
  output reg [MASK_WIDTH-1:0] slave_a_mask,
  output reg [DATA_WIDTH-1:0] slave_a_data,
  output reg                  slave_d_ready
);

  // Internal wires for DUT-driven signals (inputs to testbench)
  wire                    master_a_ready;
  wire                    master_d_valid;
  wire [OPCODE_WIDTH-1:0] master_d_opcode;
  wire [PARAM_WIDTH-1:0]  master_d_param;
  wire [SIZE_WIDTH-1:0]   master_d_size;
  wire 		          master_d_source;
  wire 		          master_d_sink;
  wire [DATA_WIDTH-1:0]   master_d_data;
  wire                    master_d_error;

  wire                      slave_a_ready;
  wire                      slave_d_valid;
  wire [OPCODE_WIDTH-1:0]   slave_d_opcode;
  wire [PARAM_WIDTH-1:0]    slave_d_param;
  wire [SIZE_WIDTH-1:0]     slave_d_size;
  wire 		            slave_d_source;
  wire 		            slave_d_sink;
  wire [DATA_WIDTH-1:0]     slave_d_data;
  wire                      slave_d_error;

  //===========================================================================  
  // Clock Generation  
  //===========================================================================  
  initial begin
    clk_100 = 0;
    forever #5  clk_100 = ~clk_100;  // 100 MHz clock (10 time unit period)
  end

  initial begin
    clk_24 = 0;
    forever #21 clk_24 = ~clk_24;   // 24 MHz clock (approximate period)
  end

  //===========================================================================  
  // Initial Setup and Stimulus  
  //===========================================================================  


  initial begin
    // Initialize signals (other than clocks, which are generated above)
    reset   = 1;
    master_a_valid = 0;
    master_a_opcode = 0;
    master_a_param  = 0;
    master_a_size   = 0;
    master_a_source = 0;
    master_a_address = 0;
    master_a_mask   = {MASK_WIDTH{1'b1}};
    master_a_data   = 0;
    master_d_ready  = 1; // Masters ready for responses

    slave_a_valid   = 0;
    slave_a_opcode  = 0;
    slave_a_param   = 0;
    slave_a_size    = 0;
    slave_a_source  = 0;
    slave_a_address = 0;
    slave_a_mask    = {MASK_WIDTH{1'b1}};
    slave_a_data    = 0;
    slave_d_ready   = 1;


    // Deassert reset after 20 time units
    #20 reset = 0;
   
    //--- Begin Stimulus Sequence ---
    // Stimulus for Master 0: Issue a Get request
    #30;
    master_a_valid = 1;
    master_a_opcode = 3'd4; // Get operation
    master_a_address = 32'h0000_1000;
    master_a_size = 3'd2; // 4-byte transfer
    master_a_data = 32'hDEAD_BEEF;
    
    wait(master_a_ready);
    @(posedge clk_100);
    master_a_valid = 0;
   
    //wait for response
    #500

    // Additional stimulus can be added here (simulate burst transactions, etc.)
    // ...
   
    // End simulation after a sufficient delay
    #1000 $finish;
  end

  //===========================================================================  
  // DUT Instantiation  
  //===========================================================================  
/*  tlul_interconnect_top #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .MASK_WIDTH(MASK_WIDTH),
    .SIZE_WIDTH(SIZE_WIDTH),
    .SRC_WIDTH(SRC_WIDTH),
    .SINK_WIDTH(SINK_WIDTH),
    .OPCODE_WIDTH(OPCODE_WIDTH),
    .PARAM_WIDTH(PARAM_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
  ) u_top (
    .clk_100(clk_100),
    .clk_24(clk_24),
    .reset(reset),
    // Master Socket Connections
    .master_a_valid(master_a_valid),
    .master_a_ready(master_a_ready),
    .master_a_opcode(master_a_opcode),
    .master_a_param(master_a_param),
    .master_a_size(master_a_size),
    .master_a_source(master_a_source),
    .master_a_address(master_a_address),
    .master_a_mask(master_a_mask),
    .master_a_data(master_a_data),
    .master_d_valid(master_d_valid),
    .master_d_ready(master_d_ready),
    .master_d_opcode(master_d_opcode),
    .master_d_param(master_d_param),
    .master_d_size(master_d_size),
    .master_d_source(master_d_source),
    .master_d_sink(master_d_sink),
    .master_d_data(master_d_data),
    .master_d_error(master_d_error),
    // Slave Socket Connections
    .slave_a_valid(slave_a_valid),
    .slave_a_ready(slave_a_ready),
    .slave_a_opcode(slave_a_opcode),
    .slave_a_param(slave_a_param),
    .slave_a_size(slave_a_size),
    .slave_a_source(slave_a_source),
    .slave_a_address(slave_a_address),
    .slave_a_mask(slave_a_mask),
    .slave_a_data(slave_a_data),
    .slave_d_ready(slave_d_ready),
    .slave_d_valid(slave_d_valid),
    .slave_d_opcode(slave_d_opcode),
    .slave_d_param(slave_d_param),
    .slave_d_size(slave_d_size),
    .slave_d_source(slave_d_source),
    .slave_d_sink(slave_d_sink),
    .slave_d_data(slave_d_data),
    .slave_d_error(slave_d_error)	
  );
*/
endmodule
