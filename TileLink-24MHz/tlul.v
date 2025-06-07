// Top-level module for TL-UL  
// 1:1 Master-Slave Interconnect 

`timescale 1ns/1ps

module tlul_system #(
    parameter ADDR_WIDTH   = 32,
    parameter DATA_WIDTH   = 32,
    parameter MASK_WIDTH   = DATA_WIDTH/8,
    parameter SIZE_WIDTH   = 3,
    parameter OPCODE_WIDTH = 3
)(
    input clk_24,
    input rst_n,

    // Master control interface
    input        start_trans,
    input [1:0]  trans_type,
    input [ADDR_WIDTH-1:0] address,
    input [SIZE_WIDTH-1:0]  size,
    input [DATA_WIDTH-1:0] write_data,
    input [MASK_WIDTH-1:0]  write_mask,

    // Master status outputs
    output wire       trans_done,
    output wire [DATA_WIDTH-1:0] read_data,

    // Slave monitoring outputs
    output wire       resp_valid,
    output wire [OPCODE_WIDTH-1:0] resp_opcode,
    output wire [DATA_WIDTH-1:0] resp_data
);

    // TileLink signals between master and slave
    wire        a_valid;
    wire        a_ready;
    wire [OPCODE_WIDTH-1:0]  a_opcode;
    wire [SIZE_WIDTH-1:0]  a_size;
    wire [ADDR_WIDTH-1:0] a_address;
    wire [MASK_WIDTH-1:0]  a_mask;
    wire [DATA_WIDTH-1:0] a_data;

    wire        d_valid;
    wire        d_ready;
    wire [OPCODE_WIDTH-1:0]  d_opcode;
    wire [SIZE_WIDTH-1:0]  d_size;
    wire [DATA_WIDTH-1:0] d_data;
    wire        d_denied; 

    // Instantiate TL-UL Master
    tlul_master #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .MASK_WIDTH(4),
        .SIZE_WIDTH(3),
        .OPCODE_WIDTH(3)
    ) u_tlul_master (
        .clk_24(clk_24),
        .rst_n(rst_n),
        
        // Control interface
        .start_trans(start_trans),
        .trans_type(trans_type),
        .trans_done(trans_done),
        .address(address),
        .size(size),
        .write_data(write_data),
        .write_mask(write_mask),
        .read_data(read_data),
        
        // TileLink Channel A
        .a_valid(a_valid),
        .a_ready(a_ready),
        .a_opcode(a_opcode),
        .a_size(a_size),
        .a_address(a_address),
        .a_mask(a_mask),
        .a_data(a_data),
        
        // TileLink Channel D
        .d_valid(d_valid),
        .d_ready(d_ready),
        .d_opcode(d_opcode),
        .d_data(d_data)
    );

    // Instantiate TL-UL Slave
    tlul_slave #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .MASK_WIDTH(4),
        .SIZE_WIDTH(3),
        .OPCODE_WIDTH(3)
    ) u_tlul_slave (
        .clk_24(clk_24),
        .rst_n(rst_n),
        
        // TileLink Channel A
        .a_valid(a_valid),
        .a_ready(a_ready),
        .a_opcode(a_opcode),
        .a_size(a_size),
        .a_address(a_address),
        .a_mask(a_mask),
        .a_data(a_data),
        
        // TileLink Channel D
        .d_valid(d_valid),
        .d_ready(d_ready),
        .d_opcode(d_opcode),
        .d_size(d_size),
        .d_denied(d_denied),          // Unused in this system
        .d_data(d_data),
        
        // Response monitoring
        .resp_valid(resp_valid),
        .resp_opcode(resp_opcode),
        .resp_data(resp_data)
    );

endmodule