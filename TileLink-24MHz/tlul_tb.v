`timescale 1ns/1ps

module tlul_tb;

    // Parameters
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter MASK_WIDTH = 4;
    parameter SIZE_WIDTH = 3;
    parameter OPCODE_WIDTH = 3;

    // Clock and reset
    reg clk_24;
    reg rst_n;

    // Master control interface
    reg        start_trans;
    reg [1:0]  trans_type;
    reg [31:0] address;
    reg [2:0]  size;
    reg [31:0] write_data;
    reg [3:0]  write_mask;

    wire       trans_done;
    wire [31:0] read_data;

    // Slave monitoring outputs
    wire       resp_valid;
    wire [2:0] resp_opcode;
    wire [31:0] resp_data;

    // Instantiate DUT (tlul_system)
    tlul_system dut (
        .clk_24(clk_24),
        .rst_n(rst_n),
        .start_trans(start_trans),
        .trans_type(trans_type),
        .address(address),
        .size(size),
        .write_data(write_data),
        .write_mask(write_mask),
        .trans_done(trans_done),
        .read_data(read_data),
        .resp_valid(resp_valid),
        .resp_opcode(resp_opcode),
        .resp_data(resp_data)
    );

    // Clock generation (24 MHz)
    initial clk_24 = 0;
    always #20.833 clk_24 = ~clk_24; // 24 MHz

    // Test sequence
    initial begin
        // Initialize
        start_trans = 0;
        trans_type = 0;
        address = 0;
        size = 0;
        write_data = 0;
        write_mask = 0;
        rst_n = 0;

        // Reset
        #50;
        rst_n = 1;
        #50;

        // Test 1: PutFullData (write) to address 0x4000_0000
        $display("\n[TEST 1] PutFullData to 0x40000000");
        trans_type = 2'b01; // PUTFULL
        address = 32'h4000_0000;
        size = 3'b010; // 4 bytes
        write_data = 32'hDEADBEEF;
        write_mask = 4'b1111;
        @(posedge clk_24);
        start_trans = 1;
        @(posedge clk_24);
        start_trans = 0;
        wait(trans_done);
        @(posedge clk_24);
        $display("[TEST 1] Done. Resp opcode: %h", resp_opcode);

        // Test 2: Get (read) from address 0x4000_0000
        $display("\n[TEST 2] Get from 0x40000000");
        trans_type = 2'b00; // GET
        address = 32'h4000_0000;
        size = 3'b010;
        @(posedge clk_24);
        start_trans = 1;
        @(posedge clk_24);
        start_trans = 0;
        wait(trans_done);
        @(posedge clk_24);
        $display("[TEST 2] Done. Read data: %h", read_data);
        if (read_data === 32'hDEADBEEF)
            $display("[TEST 2] PASS: Read matches written data");
        else
            $display("[TEST 2] FAIL: Expected DEADBEEF, got %h", read_data);
        
        // Test 3: PutFullData (write) to address 0x4000_0004
        $display("\n[TEST 3] PutFullData to 0x40000004");
        trans_type = 2'b01; // PUTFULL
        address = 32'h4000_0004;
        size = 3'b010; // 4 bytes
        write_data = 32'hCAFEBABE;
        write_mask = 4'b1111;
        @(posedge clk_24);
        start_trans = 1;
        @(posedge clk_24);
        start_trans = 0;
        wait(trans_done);
        @(posedge clk_24);

        $display("[TEST 3] Done. Resp opcode: %h", resp_opcode);

        // Test 4: Get (read) from address 0x4000_0004
        $display("\n[TEST 4] Get from 0x40000004");
        trans_type = 2'b00; // GET
        address = 32'h4000_0004;
        size = 3'b010;
        @(posedge clk_24);
        start_trans = 1;
        @(posedge clk_24);
        start_trans = 0;
        wait(trans_done);
        @(posedge clk_24);

        $display("[TEST 4] Done. Read data: %h", read_data);
        if (read_data === 32'hCAFEBABE)
            $display("[TEST 4] PASS: Read matches written data");
        else
            $display("[TEST 4] FAIL: Expected CAFEBABE, got %h", read_data);

        $display("\nAll tests completed.");
        #100;
        $finish;
        
    end

endmodule