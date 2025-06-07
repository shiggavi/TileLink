`timescale 1ns/1ps

module tb_master;

    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter MASK_WIDTH = DATA_WIDTH/8;
    parameter SIZE_WIDTH = 3;
    parameter OPCODE_WIDTH = 3;

    // Clock and reset
    reg clk_24;
    reg rst_n;

    // Control signals
    reg        start_trans;
    reg [1:0]  trans_type;
    wire       trans_done;

    reg  [ADDR_WIDTH-1:0] address;
    reg  [SIZE_WIDTH-1:0] size;
    reg  [DATA_WIDTH-1:0] write_data;
    reg  [MASK_WIDTH-1:0] write_mask;
    wire [DATA_WIDTH-1:0] read_data;

    // TileLink Channel A
    wire        a_valid;
    reg         a_ready;
    wire [OPCODE_WIDTH-1:0] a_opcode;
    wire [SIZE_WIDTH-1:0] a_size;
    wire [ADDR_WIDTH-1:0] a_address;
    wire [MASK_WIDTH-1:0] a_mask;
    wire [DATA_WIDTH-1:0] a_data;

    // TileLink Channel D
    reg         d_valid;
    wire        d_ready;
    reg  [OPCODE_WIDTH-1:0] d_opcode;
    reg  [DATA_WIDTH-1:0] d_data;

    // Simple memory model for slave
    reg [DATA_WIDTH-1:0] mem [0:3];

    // Instantiate DUT
    tlul_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MASK_WIDTH(MASK_WIDTH),
        .SIZE_WIDTH(SIZE_WIDTH),
        .OPCODE_WIDTH(OPCODE_WIDTH)
    ) dut (
        .clk_24(clk_24),
        .rst_n(rst_n),
        .start_trans(start_trans),
        .trans_type(trans_type),
        .trans_done(trans_done),
        .address(address),
        .size(size),
        .write_data(write_data),
        .write_mask(write_mask),
        .read_data(read_data),
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
        .d_data(d_data)
    );

    // Clock generation
    initial clk_24 = 0;
    always #10 clk_24 = ~clk_24; // 50MHz

    // Always ready
    initial a_ready = 1;

    // Simulate slave response (holds d_valid until d_ready)
    reg pending_response;
    reg [OPCODE_WIDTH-1:0] pending_opcode;
    reg [DATA_WIDTH-1:0] pending_data;
    always @(posedge clk_24) begin
        if (!rst_n) begin
            d_valid <= 0;
            d_opcode <= 0;
            d_data <= 0;
            pending_response <= 0;
            pending_opcode <= 0;
            pending_data <= 0;
            mem[0] <= 0;
            mem[1] <= 0;
            mem[2] <= 0;
            mem[3] <= 0;
        end else begin
            if (pending_response && d_ready) begin
                d_valid <= 0;
                pending_response <= 0;
            end else if (a_valid && a_ready && !pending_response) begin
                // Simulate write
                if (a_opcode == 3'h1) begin // PutFullData
                    mem[a_address[3:2]] <= a_data;
                    d_valid <= 1;
                    d_opcode <= 3'h3; // AccessAck
                    d_data <= 0;
                    pending_response <= 1;
                    pending_opcode <= 3'h3;
                    pending_data <= 0;
                end
                // Simulate read
                else if (a_opcode == 3'h0) begin // Get
                    d_valid <= 1;
                    d_opcode <= 3'h4; // AccessAckData
                    d_data <= mem[a_address[3:2]];
                    pending_response <= 1;
                    pending_opcode <= 3'h4;
                    pending_data <= mem[a_address[3:2]];
                end
            end else if (pending_response) begin
                d_valid <= 1;
                d_opcode <= pending_opcode;
                d_data <= pending_data;
            end else begin
                d_valid <= 0;
            end
        end
    end

    // Test sequence
    initial begin
        // Initialize
        rst_n = 0;
        start_trans = 0;
        trans_type = 0;
        address = 0;
        size = 0;
        write_data = 0;
        write_mask = 4'b1111;
        d_valid = 0;
        d_opcode = 0;
        d_data = 0;

        #50;
        rst_n = 1;
        #20;

        // Test 1: PutFullData (write)
        $display("[TEST 1] PutFullData (write)");
        address = 32'h0000_0000;
        size = 3'h2;
        write_data = 32'hA5A5_1234;
        trans_type = 2'b01; // PutFullData
        @(posedge clk_24);
        start_trans = 1;
        @(posedge clk_24);
        start_trans = 0;
        wait(trans_done);
        @(posedge clk_24);
        $display("  Write done.");

        // Test 2: Get (read)
        $display("[TEST 2] Get (read)");
        address = 32'h0000_0000;
        size = 3'h2;
        trans_type = 2'b00; // Get
        @(posedge clk_24);
        start_trans = 1;
        @(posedge clk_24);
        start_trans = 0;
        wait(trans_done);
        @(posedge clk_24);
        $display("  Read data: %h", read_data);
        if (read_data == 32'hA5A5_1234)
            $display("  PASS: Read matches written data");
        else
            $display("  FAIL: Read mismatch");

        $display("All tests completed.");
        #50;
        $finish;
    end

endmodule