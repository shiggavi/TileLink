`timescale 1ns/1ps

module tlul_interconnect_monitor #(
  parameter DATA_WIDTH   = 32,
  parameter ADDR_WIDTH   = 32,
  parameter MASK_WIDTH   = DATA_WIDTH/8,
  parameter SIZE_WIDTH   = 3,
  parameter SRC_WIDTH    = 2,
  parameter SINK_WIDTH   = 1,
  parameter OPCODE_WIDTH = 3,
  parameter PARAM_WIDTH  = 3
)(
  input                         clk,
  input                         reset,
  
  // Master Interface Signals (DUT -> Master)
  input  [2:0]                  master_a_valid,
  input  [2:0]                  master_a_ready,
  input  [3*ADDR_WIDTH-1:0]     master_a_address,
  input  [3*DATA_WIDTH-1:0]     master_a_data,
  input  [3*OPCODE_WIDTH-1:0]   master_a_opcode,
  input  [3*SIZE_WIDTH-1:0]     master_a_size,
  
  input  [2:0]                  master_d_valid,
  input  [3*DATA_WIDTH-1:0]     master_d_data,
  input  [3*OPCODE_WIDTH-1:0]   master_d_opcode,
  input  [3*SIZE_WIDTH-1:0]     master_d_size,
  input  [2:0]                  master_d_error,

  // Slave Interface Signals (Slave -> DUT)
  input                        slave_a_valid,
  input                        slave_a_ready,
  input  [3*ADDR_WIDTH-1:0]    slave_a_address,
  input  [3*DATA_WIDTH-1:0]    slave_a_data,
  input  [OPCODE_WIDTH-1:0]    slave_a_opcode,
  input  [SIZE_WIDTH-1:0]      slave_a_size,

  input                        slave_d_valid,
  input  [DATA_WIDTH-1:0]      slave_d_data,
  input  [OPCODE_WIDTH-1:0]    slave_d_opcode,
  input  [SIZE_WIDTH-1:0]      slave_d_size,
  input                        slave_d_error
);

  integer i;

  // Monitor Master A Channel Transactions
  always @(posedge clk) begin
    if (!reset) begin
      for (i = 0; i < 3; i = i + 1) begin
        if (master_a_valid[i] && master_a_ready[i]) begin
          $display("[%0t] Master%0d A-Request: Opcode=%0d Addr=0x%08x Size=%0d Data=0x%08x",
                   $time, i,
                   master_a_opcode[i*OPCODE_WIDTH +: OPCODE_WIDTH],
                   master_a_address[i*ADDR_WIDTH +: ADDR_WIDTH],
                   master_a_size[i*SIZE_WIDTH +: SIZE_WIDTH],
                   master_a_data[i*DATA_WIDTH +: DATA_WIDTH]);
        end
      end
    end
  end

  // Monitor Master D Channel Responses
  always @(posedge clk) begin
    if (!reset) begin
      for (i = 0; i < 3; i = i + 1) begin
        if (master_d_valid[i]) begin
          $display("[%0t] Master%0d D-Response: Opcode=%0d Data=0x%08x Size=%0d Error=%0b",
                   $time, i,
                   master_d_opcode[i*OPCODE_WIDTH +: OPCODE_WIDTH],
                   master_d_data[i*DATA_WIDTH +: DATA_WIDTH],
                   master_d_size[i*SIZE_WIDTH +: SIZE_WIDTH],
                   master_d_error[i]);
        end
      end
    end
  end

  // Monitor Slave A Channel
  always @(posedge clk) begin
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
  always @(posedge clk) begin
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

