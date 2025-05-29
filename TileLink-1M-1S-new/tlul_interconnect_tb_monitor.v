`timescale 1ns/1ps

module tlul_interconnect_monitor #(
  parameter DATA_WIDTH   = 32,
  parameter ADDR_WIDTH   = 32,
  parameter MASK_WIDTH   = DATA_WIDTH/8,
  parameter SIZE_WIDTH   = 3,
  parameter SRC_WIDTH    = 1,
  parameter SINK_WIDTH   = 1,
  parameter OPCODE_WIDTH = 3,
  parameter PARAM_WIDTH  = 3
)(

  
  // Master Interface Signals (DUT -> Master)
  input reg                      master_a_ready,


  // Interconnect -> Master (TileLink Channel D response)
  input reg                      master_d_valid,

  input reg [OPCODE_WIDTH-1:0]   master_d_opcode,
  input reg [PARAM_WIDTH-1:0]    master_d_param,
  input reg [SIZE_WIDTH-1:0]     master_d_size,
  input reg 		          master_d_source,
  input reg                      master_d_sink,
  input reg [DATA_WIDTH-1:0]     master_d_data,
  input reg                      master_d_error,

  // --------------------- Slave Socket Interface ---------------------
  // Interconnect -> Slave (Channel A request)
  input reg               slave_a_valid,

  input reg [OPCODE_WIDTH-1:0] slave_a_opcode,
  input reg [PARAM_WIDTH-1:0]  slave_a_param,
  input reg [SIZE_WIDTH-1:0]   slave_a_size,
  input reg 		        slave_a_source,
  input reg [ADDR_WIDTH-1:0]   slave_a_address,
  input reg [MASK_WIDTH-1:0]   slave_a_mask,
  input reg [DATA_WIDTH-1:0]   slave_a_data,

  // Slave -> Interconnect (Channel D response)

  input reg                 slave_d_ready,
);



  // Monitor Master A Channel Transactions
  always @(posedge clk_24) begin
    if (!reset && master_a_valid && master_a_ready) begin
          $display("[%0t] Master A-Request: Opcode=%0d Addr=0x%08x Size=%0d Data=0x%08x",
                   $time,
                   master_a_opcode,
                   master_a_address,
                   master_a_size,
                   master_a_data);
    end
  end
    
  

  // Monitor Master D Channel Responses
  always @(posedge clk_24) begin
    if (!reset && master_d_valid) begin
          $display("[%0t] Master D-Response: Opcode=%0d Data=0x%08x Size=%0d Error=%0b",
                   $time,
                   master_d_opcode,
                   master_d_data,
                   master_d_size,
                   master_d_error);
    end
  end

  // Monitor Slave A Channel
  always @(posedge clk_24) begin
    if (!reset && slave_a_valid && slave_a_ready) begin
      $display("[%0t] Slave A-Request: Opcode=%0d Addr=0x%08x Size=%0d Data=0x%08x",
               $time,
               slave_a_opcode,
               slave_a_address[ADDR_WIDTH-1:0], // Assume first slave channel
               slave_a_size,
               slave_a_data[DATA_WIDTH-1:0]);
    end
  end

  // Monitor Slave D Channel
  always @(posedge clk_24) begin
    if (!reset && slave_d_valid) begin
      $display("[%0t] Slave D-Response: Opcode=%0d Data=0x%08x Size=%0d Error=%0b",
               $time,
               slave_d_opcode,
               slave_d_data,
               slave_d_size,
               slave_d_error);
    end
  end

endmodule

