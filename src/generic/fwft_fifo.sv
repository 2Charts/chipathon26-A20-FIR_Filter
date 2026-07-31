module fwft_fifo # (
    parameter DATA_WIDTH = 16,
    parameter DATA_DEPTH = 8,
    parameter ADDR_WIDTH = $clog2(DATA_DEPTH)
) (
    input   logic                   rd_en_i,
    output  logic [DATA_WIDTH-1:0]  rd_data_o,

    input   logic                   wr_en_i,
    input   logic [DATA_WIDTH-1:0]  wr_data_i,

    output  logic                   empty_o,
    output  logic                   full_o,

    input   logic                   arst_n,
    input   logic                   clk
);
    logic [DATA_WIDTH-1:0] memory [0:DATA_DEPTH-1];

    logic [ADDR_WIDTH:0] wr_ptr;
    logic [ADDR_WIDTH:0] rd_ptr;

    logic empty;
    logic full;

    assign empty = (wr_ptr == rd_ptr) ? 1'b1 : 1'b0;
    assign full  = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH] && 
                    wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]) ? 1'b1 : 1'b0;

    assign empty_o = empty;
    assign full_o  = full;

    always_ff @(posedge clk or negedge arst_n) begin : WRITE
        if (!arst_n) begin
            wr_ptr <= 0;
        end 
        else if (wr_en_i && !full) begin
            memory[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data_i;
            wr_ptr <= wr_ptr + 1;
        end
    end

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            rd_ptr <= 0;
        end 
        else if (rd_en_i && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    assign rd_data_o = memory[rd_ptr[ADDR_WIDTH-1:0]];

endmodule
