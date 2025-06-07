
`timescale 1ns/1ps

module tlul_master #(
    parameter ADDR_WIDTH   = 32,
    parameter DATA_WIDTH   = 32,
    parameter MASK_WIDTH   = DATA_WIDTH/8,
    parameter SIZE_WIDTH   = 3,
    parameter OPCODE_WIDTH = 3
)(
    input clk_24,
    input rst_n,

    // Control signals
    input        start_trans,      // Pulse to start a new transaction
    input [1:0]  trans_type,       // 0: GET, 1: PUTFULL
    output reg   trans_done,       // Pulses when transaction is complete

    // Transaction parameters
    input [ADDR_WIDTH-1:0]     address,
    input [SIZE_WIDTH-1:0]     size,
    input [DATA_WIDTH-1:0]     write_data,
    input [MASK_WIDTH-1:0]     write_mask,
    output reg [DATA_WIDTH-1:0] read_data,

    // TileLink Channel A (Master -> Slave)
    output reg         a_valid,
    input              a_ready,
    output reg [OPCODE_WIDTH-1:0]   a_opcode,
    output reg [SIZE_WIDTH-1:0] a_size,
    output reg [ADDR_WIDTH-1:0] a_address,
    output reg [MASK_WIDTH-1:0] a_mask,
    output reg [DATA_WIDTH-1:0] a_data,

    // TileLink Channel D (Slave -> Master)
    input              d_valid,
    output reg         d_ready,
    input [OPCODE_WIDTH-1:0]        d_opcode,
    input [DATA_WIDTH-1:0] d_data
);

    // Opcodes
    localparam [2:0] Get         = 3'h0;
    localparam [2:0] PutFullData = 3'h1;
    localparam [2:0] AccessAck   = 3'h3;
    localparam [2:0] AccessAckData = 3'h4;

    // FSM states
    //localparam S_IDLE      = 2'b00;
    localparam SEND_REQ  = 1'b0;
    localparam WAIT_RESP = 1'b1;


    reg state, next_state;
    //reg [1:0] prev_state;

/*
    reg [1:0] tx_type_reg;
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg [SIZE_WIDTH-1:0] size_reg;
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg [MASK_WIDTH-1:0] wmask_reg;
*/

    // FSM state register and prev_state for transition detection
    always @(posedge clk_24 or negedge rst_n) begin
        if (!rst_n)
            state <= SEND_REQ;
        else 
            state <= next_state;
    end

    // FSM next state logic
    always @(*) begin
        next_state = state;
        case (state)
            SEND_REQ: begin
                if (start_trans && a_ready)
                    next_state = WAIT_RESP;
            end
            WAIT_RESP: begin
                if (d_valid && d_ready)
                    next_state = SEND_REQ;
            end
        endcase
    end

/*
    // Latch transaction parameters
    always @(posedge clk_24 or negedge rst_n) begin
        if (!rst_n) begin
            tx_type_reg <= 0;
            addr_reg    <= 0;
            size_reg    <= 0;
            wdata_reg   <= 0;
            wmask_reg   <= 0;
        end else if (state == S_IDLE && start_trans) begin
            tx_type_reg <= trans_type;
            addr_reg    <= address;
            size_reg    <= size;
            wdata_reg   <= write_data;
            wmask_reg   <= write_mask;
        end
    end
*/

    // Output and handshake logic
    always @(*) begin
        // Defaults
        a_valid   = 0;
        a_opcode  = 0;
        a_size    = 0;
        a_address = 0;
        a_mask    = 0;
        a_data    = 0;
        d_ready   = 1;
        trans_done = 0;

        case (state)
            SEND_REQ: begin
                if (start_trans) begin
                    a_valid   = 1;
                    a_size    = size;
                    a_address = address;
                    a_data    = write_data;
                    a_mask    = write_mask;
                    a_opcode  = (trans_type == 2'b00) ? Get : PutFullData;
                end
            end
            WAIT_RESP: begin
                if (d_valid && d_ready)
                    trans_done = 1;
            end
        endcase
    end

/*
    // Pulse trans_done for one clock when transaction completes
    always @(posedge clk_24 or negedge rst_n) begin
        if (!rst_n)
            trans_done <= 1'b0;
        else if (prev_state == S_WAIT_RESP && state == S_IDLE)
            trans_done <= 1'b1;
        else
            trans_done <= 1'b0;
    end
*/

    // Capture read data

    assign read_data = (state == WAIT_RESP && d_valid && d_ready && d_opcode == AccessAckData) ? d_data : {DATA_WIDTH{1'b0}};
   
/*   
    always @(posedge clk_24 or negedge rst_n) begin
        if (!rst_n)
            read_data <= 0;
        else if (state == WAIT_RESP && d_valid && d_ready && d_opcode == AccessAckData)
            read_data <= d_data;
    end
*/
endmodule