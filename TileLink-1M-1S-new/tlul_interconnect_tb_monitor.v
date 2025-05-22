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
  input                         clk_24,
  input                         clk_100,
  input                         reset,
  
  // Master Interface Signals (DUT -> Master)
  input                    master_a_valid,
  input                    master_a_ready,
  input  [ADDR_WIDTH-1:0]     master_a_address,
  input  [DATA_WIDTH-1:0]     master_a_data,
  input  [OPCODE_WIDTH-1:0]   master_a_opcode,
  input  [SIZE_WIDTH-1:0]     master_a_size,
  
  input                    master_d_valid,
  input  [DATA_WIDTH-1:0]     master_d_data,
  input  [OPCODE_WIDTH-1:0]   master_d_opcode,
  input  [SIZE_WIDTH-1:0]     master_d_size,
  input                    master_d_error,
input [PARAM_WIDTH-1:0]    master_d_param,
input master_d_source,
input master_d_sink,



  // Slave Interface Signals (Slave -> DUT)
  input                        slave_a_valid,
  input                        slave_a_ready,
  input  [ADDR_WIDTH-1:0]    slave_a_address,
  input  [DATA_WIDTH-1:0]    slave_a_data,
  input  [OPCODE_WIDTH-1:0]    slave_a_opcode,
  input  [SIZE_WIDTH-1:0]      slave_a_size,
input [PARAM_WIDTH-1:0]  slave_a_param,
input slave_a_source,
input [MASK_WIDTH-1:0]   slave_a_mask,


input slave_d_ready,
  input                        slave_d_valid,
  input  [DATA_WIDTH-1:0]      slave_d_data,
  input  [OPCODE_WIDTH-1:0]    slave_d_opcode,
  input  [SIZE_WIDTH-1:0]      slave_d_size,
  input                        slave_d_error
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

