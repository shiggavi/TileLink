`timescale 1ns / 1ps
`include "tlul_interconnect_top.v"
module tlul_interconnect_tb();

  // Clock and reset signals
  reg clk_24, reset;

  // Generate 100 MHz clock (10 ns period)
/*
    initial begin
    clk_100 = 0;
    forever #5 clk_100 = ~clk_100;
  end
*/


  // Generate 24 MHz clock (~41.67 ns period)
  initial begin
    clk_24 = 0;
    forever #21 clk_24 = ~clk_24;
  end

  // Reset generation
  initial begin
    reset = 1;
    #20 reset = 0;
  end

  // Parameters
  parameter OPCODE_WIDTH = 3;
  parameter PARAM_WIDTH  = 3;
  parameter SIZE_WIDTH   = 3;
  parameter SRC_WIDTH    = 1;
  parameter SINK_WIDTH   = 1;
  parameter ADDR_WIDTH   = 32;
  parameter DATA_WIDTH   = 32;
  parameter MASK_WIDTH   = DATA_WIDTH / 8;

  // Master interface signals
  reg                          master_a_valid;
  wire                         master_a_ready;
  reg  [OPCODE_WIDTH-1:0]      master_a_opcode;
  reg  [PARAM_WIDTH-1:0]       master_a_param;
  reg  [SIZE_WIDTH-1:0]        master_a_size;
  reg            master_a_source;
  reg  [ADDR_WIDTH-1:0]        master_a_address;
  reg  [MASK_WIDTH-1:0]        master_a_mask;
  reg  [DATA_WIDTH-1:0]        master_a_data;

  wire                         master_d_valid;
  reg                          master_d_ready;
  wire [OPCODE_WIDTH-1:0]      master_d_opcode;
  wire [PARAM_WIDTH-1:0]       master_d_param;
  wire [SIZE_WIDTH-1:0]        master_d_size;
  wire          master_d_source;
  wire          master_d_sink;
  wire [DATA_WIDTH-1:0]        master_d_data;
  wire                         master_d_error;

  // Slave interface signals
  wire                         slave_a_valid;
  reg                          slave_a_ready;
  wire [OPCODE_WIDTH-1:0]      slave_a_opcode;
  wire [PARAM_WIDTH-1:0]       slave_a_param;
  wire [SIZE_WIDTH-1:0]        slave_a_size;
  wire            slave_a_source;
  wire [ADDR_WIDTH-1:0]        slave_a_address;
  wire [MASK_WIDTH-1:0]        slave_a_mask;
  wire [DATA_WIDTH-1:0]        slave_a_data;

  reg                          slave_d_valid;
  wire                         slave_d_ready;
  reg  [OPCODE_WIDTH-1:0]      slave_d_opcode;
  reg  [PARAM_WIDTH-1:0]       slave_d_param;
  reg  [SIZE_WIDTH-1:0]        slave_d_size;
  reg            slave_d_source;
  reg            slave_d_sink;
  reg  [DATA_WIDTH-1:0]        slave_d_data;
  reg                          slave_d_error;

  // Instantiate the Device Under Test (DUT)
  tlul_interconnect_top u_top (
    .clk_24         (clk_24),
    .reset          (reset),
    .master_a_valid (master_a_valid),
    .master_a_ready (master_a_ready),
    .master_a_opcode(master_a_opcode),
    .master_a_param (master_a_param),
    .master_a_size  (master_a_size),
    .master_a_source(master_a_source),
    .master_a_address(master_a_address),
    .master_a_mask  (master_a_mask),
    .master_a_data  (master_a_data),
    .master_d_valid (master_d_valid),
    .master_d_ready (master_d_ready),
    .master_d_opcode(master_d_opcode),
    .master_d_param (master_d_param),
    .master_d_size  (master_d_size),
    .master_d_source(master_d_source),
    .master_d_sink  (master_d_sink),
    .master_d_data  (master_d_data),
    .master_d_error (master_d_error),
    .slave_a_valid  (slave_a_valid),
    .slave_a_ready  (slave_a_ready),
    .slave_a_opcode (slave_a_opcode),
    .slave_a_param  (slave_a_param),
    .slave_a_size   (slave_a_size),
    .slave_a_source (slave_a_source),
    .slave_a_address(slave_a_address),
    .slave_a_mask   (slave_a_mask),
    .slave_a_data   (slave_a_data),
    .slave_d_valid  (slave_d_valid),
    .slave_d_ready  (slave_d_ready),
    .slave_d_opcode (slave_d_opcode),
    .slave_d_param  (slave_d_param),
    .slave_d_size   (slave_d_size),
    .slave_d_source (slave_d_source),
    .slave_d_sink   (slave_d_sink),
    .slave_d_data   (slave_d_data),
    .slave_d_error  (slave_d_error)
  );

  // Task to drive a PutFullData transaction
  task drive_put;
    input [ADDR_WIDTH-1:0] addr;
    input [DATA_WIDTH-1:0] data_val;
    begin
      @(posedge clk_24);
      master_a_valid   <= 1'b1;
      master_a_opcode  <= 3'd0; // PutFullData
      master_a_param   <= 3'd0;
      master_a_size    <= 3'd2; // 4-byte access
      master_a_source  <= 1'b0;
      master_a_address <= addr;
      master_a_mask    <= {MASK_WIDTH{1'b1}};
      master_a_data    <= data_val;

      wait(master_a_ready);
      @(posedge clk_24);
      master_a_valid <= 1'b0;

      $display("[%t] MASTER: Sent PutFullData to addr=0x%h, data=0x%h", $time, addr, data_val);
    end
  endtask

  // Task to drive a Get transaction
  task drive_get;
    input [ADDR_WIDTH-1:0] addr;
    begin
      @(posedge clk_24);
      master_a_valid   <= 1'b1;
      master_a_opcode  <= 3'd4; // Get
      master_a_param   <= 3'd0;
      master_a_size    <= 3'd2; // 4-byte access
      master_a_source  <= 1'b0;
      master_a_address <= addr;
      master_a_mask    <= {MASK_WIDTH{1'b1}};
      master_a_data    <= {DATA_WIDTH{1'b0}};

      wait(master_a_ready);
      @(posedge clk_24);
      master_a_valid <= 1'b0;

      $display("[%t] MASTER: Sent Get to addr=0x%h", $time, addr);
    end
  endtask

  // Monitor Slave Requests
  always @(posedge clk_24) begin
    if (slave_a_valid && slave_a_ready) begin
      $display("[%t] SLAVE: Received %s request @0x%h, Data=0x%h",
              $time,
              (slave_a_opcode == 0) ? "PUT" : "GET",
              slave_a_address,
              slave_a_data);
    end
  end

  // Monitor Slave Responses
  always @(posedge clk_24) begin
    if (slave_d_valid && slave_d_ready) begin
      $display("[%t] SLAVE: Sent Response: %s, Data=0x%h%s",
              $time,
              (slave_d_opcode == 0) ? "PutAck" : "GetResp",
              slave_d_data,
              slave_d_error ? " [ERROR]" : "");
    end
  end

  // Monitor Master Responses
  always @(posedge clk_24) begin
    if (master_d_valid && master_d_ready) begin
      $display("[%t] MASTER: Received %s, Data=0x%h%s",
              $time,
              (master_d_opcode == 0) ? "PutAck" : "GetResp",
              master_d_data,
              master_d_error ? " [ERROR]" : "");
    end
  end

  // Test sequence
  initial begin
    // Initialize signals
    master_a_valid   = 1'b0;
    master_a_opcode  = 3'd0;
    master_a_param   = 3'd0;
    master_a_size    = 3'd2;
    master_a_source  = 1'b0;
    master_a_address = 32'd0;
    master_a_mask    = {MASK_WIDTH{1'b1}};
    master_a_data    = 32'd0;
    master_d_ready   = 1'b1;

    slave_a_ready    = 1'b0;
    slave_d_valid    = 1'b0;
    slave_d_opcode   = 3'd0;
    slave_d_param    = 3'd0;
    slave_d_size     = 3'd0;
    slave_d_source   = 1'b0;
    slave_d_sink     = 1'b0;
    slave_d_data     = 32'd0;
    slave_d_error    = 1'b0;

    @(negedge reset);
    #30;

    // Issue a PutFullData request
    drive_put(32'h0000_1000, 32'hA5A5_A5A5);

    // Issue a Get request
    drive_get(32'h0000_2000);

    // Allow the slave to start accepting requests
    slave_a_ready = 1'b1;

    #100;
    slave_d_valid <= 1'b1;
    slave_d_opcode <= 3'd1; // AccessAckData
    slave_d_data <= 32'h12345678;
    wait(slave_d_ready);
    @(posedge clk_24);
    slave_d_valid <= 1'b0;

    repeat(20) @(posedge clk_24);
    $finish;
  end
  

endmodule

