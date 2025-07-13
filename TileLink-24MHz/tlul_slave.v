`timescale 1ns/1ps

module tlul_slave #(
    parameter ADDR_WIDTH   = 32,
    parameter DATA_WIDTH   = 32,
    parameter MASK_WIDTH   = DATA_WIDTH/8,
    parameter SIZE_WIDTH   = 3,
    parameter OPCODE_WIDTH = 3
)(
    input clk_24,
    input rst_n,

    // TileLink Interface
    input        a_valid,
    output wire   a_ready,
    input [OPCODE_WIDTH-1:0]  a_opcode,
    input [SIZE_WIDTH-1:0]  a_size,
    input [ADDR_WIDTH-1:0] a_address,
    input [MASK_WIDTH-1:0]  a_mask,
    input [DATA_WIDTH-1:0] a_data,

    output       d_valid,
    input        d_ready,
    output  [OPCODE_WIDTH-1:0] d_opcode,
    output  [SIZE_WIDTH-1:0] d_size,
    output       d_denied,
    output  [DATA_WIDTH-1:0] d_data,

    // Response monitoring outputs  
    output                               resp_valid,
    output  [OPCODE_WIDTH-1:0]           resp_opcode,
    output  [DATA_WIDTH-1:0]             resp_data
);
 
    // Channel-A opcodes 
    localparam [2:0] Get            = 3'h0;
    localparam [2:0] PutFullData    = 3'h1;
    localparam [2:0] PutPartialData = 3'h2;
    

    // Channel-D opcodes
    localparam [2:0] AccessAck     = 3'h3;
    localparam [2:0] AccessAckData = 3'h4;

    // ------------- Memory Configuration -------------
    localparam MEM_DEPTH = 1024;     // 1024 words = 4KB
    localparam ADDR_BASE = 32'h4000_0000;
    reg [31:0] memory [0:MEM_DEPTH-1];
    
    // Address calculation
    wire [31:0] byte_offset = a_address - ADDR_BASE;
    wire [9:0] word_index = byte_offset[11:2];
    wire address_valid = (a_address >= ADDR_BASE) && 
                         (byte_offset < 4096);

    // Combinational response generation
    wire [31:0] mem_read_data = address_valid ? memory[word_index] : 32'hDEADBEEF;
    wire        is_read = (a_opcode == Get);
    wire        is_write = (a_opcode == PutFullData || a_opcode == PutPartialData);
    
    // FSM states
    localparam S_IDLE = 1'b0;
    localparam S_RESP = 1'b1;

    reg state, next_state;
    reg d_valid_reg;
    reg [OPCODE_WIDTH-1:0] d_opcode_reg;
    reg [SIZE_WIDTH-1:0] d_size_reg;
    reg d_denied_reg;
    reg [DATA_WIDTH-1:0] d_data_reg;

    integer i;
    assign a_ready = 1'b1; // Always ready to accept requests
    
    // Synchronous reset for memory
    always @(posedge clk_24 or negedge rst_n) begin
       if (!rst_n) begin
            for (i=0; i<MEM_DEPTH; i=i+1) 
                memory[i] = 32'h0;
       end else if (a_valid && is_write && address_valid) begin
           memory[word_index] <= a_data;
       end
    end

    // FSM combinational logic
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (a_valid && a_ready)
                    next_state = S_RESP;
            end
            S_RESP: begin
                if (d_ready && d_valid_reg)
                    next_state = S_IDLE;
            end
            default: next_state = S_IDLE;
        endcase
    end

  
    // FSM sequential logic
    always @(posedge clk_24 or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            d_valid_reg <= 1'b0;
            d_opcode_reg <= {OPCODE_WIDTH{1'b0}};
            d_size_reg <= {SIZE_WIDTH{1'b0}};
            d_denied_reg <= 1'b0;
            d_data_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            state <= next_state;
            if (state == S_IDLE) begin
                if (a_valid && a_ready) begin
                    d_valid_reg <= 1'b1;
                    d_size_reg <= a_size;
                    d_denied_reg <= !address_valid;
                    if (a_opcode == Get) begin
                        d_opcode_reg <= AccessAckData;
                        d_data_reg <= mem_read_data;
                    end else if (a_opcode == PutFullData || a_opcode == PutPartialData) begin
                        d_opcode_reg <= AccessAck;
                        d_data_reg <= 32'h0;
                    end else begin
                        d_opcode_reg <= {OPCODE_WIDTH{1'b0}};
                        d_data_reg <= 32'h0;
                    end
                end else begin
                    d_valid_reg <= 1'b0;
                end
            end else if (state == S_RESP) begin
                if (d_ready && d_valid_reg)
                    d_valid_reg <= 1'b0;
            end
        end
    end

    // Assign registered outputs
    assign d_valid = d_valid_reg;
    assign d_opcode = d_opcode_reg;
    assign d_size = d_size_reg;
    assign d_denied = d_denied_reg;
    assign d_data = d_data_reg;

    assign resp_data = d_data_reg;
    assign resp_opcode = d_opcode_reg;
    assign resp_valid = d_valid_reg;

endmodule
