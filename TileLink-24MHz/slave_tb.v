`timescale 1ns/1ps

module tb_tlul_slave;

    // Parameters
    parameter ADDR_WIDTH   = 32;
    parameter DATA_WIDTH   = 32;
    parameter MASK_WIDTH   = DATA_WIDTH/8;
    parameter SIZE_WIDTH   = 3;
    parameter OPCODE_WIDTH = 3;

    // DUT signals
    reg clk_24;
    reg rst_n;

    reg                   a_valid;
    wire                  a_ready;
    reg  [OPCODE_WIDTH-1:0] a_opcode;
    reg  [SIZE_WIDTH-1:0]   a_size;
    reg  [ADDR_WIDTH-1:0]   a_address;
    reg  [MASK_WIDTH-1:0]   a_mask;
    reg  [DATA_WIDTH-1:0]   a_data;

    wire                  d_valid;
    reg                   d_ready;
    wire [OPCODE_WIDTH-1:0] d_opcode;
    wire [SIZE_WIDTH-1:0]   d_size;
    wire                  d_denied;
    wire [DATA_WIDTH-1:0]  d_data;

    wire                  resp_valid;
    wire [OPCODE_WIDTH-1:0] resp_opcode;
    wire [DATA_WIDTH-1:0]   resp_data;

    // Instantiate DUT
    tlul_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MASK_WIDTH(MASK_WIDTH),
        .SIZE_WIDTH(SIZE_WIDTH),
        .OPCODE_WIDTH(OPCODE_WIDTH)
    ) dut (
        .clk_24(clk_24),
        .rst_n(rst_n),
        .a_valid(a_valid),
        .a_ready(a_ready),
        .a_opcode(a_opcode),
        .a_size(a_size),
        .a_address(a_address),
        .a_mask(a_mask),
        .a_data(a_data),
        .d_valid(d_valid),
        .d_ready(d_ready),
        .d_opcode(d_opcode),
        .d_size(d_size),
        .d_denied(d_denied),
        .d_data(d_data),
        .resp_valid(resp_valid),
        .resp_opcode(resp_opcode),
        .resp_data(resp_data)
    );

    // Clock generation
    initial clk_24 = 0;
    always #5 clk_24 = ~clk_24; // 100MHz for simulation

    // Test sequence
    initial begin
        // Initialize
        a_valid = 0;
        a_opcode = 0;
        a_address = 0;
        a_data = 0;
        a_mask = 0;
        a_size = 0;
        d_ready = 1;
        rst_n = 0;

        // Reset
        #20;
        rst_n = 1;
        #20;

        // Test 1: PutFullData (write)
        $display("Test 1: PutFullData (write)");
        @(posedge clk_24);
        a_address = 32'h4000_0000;
        a_data    = 32'hA5A5_1234;
        a_mask    = 4'b1111;
        a_opcode  = 3'h1; // PutFullData
        a_size    = 3'h2;
        a_valid   = 1;
        @(posedge clk_24);
        a_valid   = 0;

        // Wait for response
        wait(d_valid);
        if (d_opcode == 3'h3 && d_data == 32'h0 && !d_denied)
            $display("  PASS: Write acknowledged");
        else
            $display("  FAIL: Write response incorrect: opcode=%h data=%h denied=%b", d_opcode, d_data, d_denied);

        @(posedge clk_24);

        // Test 2: Get (read)
        $display("Test 2: Get (read)");
        a_address = 32'h4000_0000;
        a_opcode  = 3'h0; // Get
        a_size    = 3'h2;
        a_valid   = 1;
        @(posedge clk_24);
        a_valid   = 0;

        // Wait for response
        wait(d_valid);
        if (d_opcode == 3'h4 && d_data == 32'hA5A5_1234 && !d_denied)
            $display("  PASS: Read correct data");
        else
            $display("  FAIL: Read response incorrect: opcode=%h data=%h denied=%b", d_opcode, d_data, d_denied);

        #20;
        $display("Testbench completed.");
        $finish;
    end

endmodule