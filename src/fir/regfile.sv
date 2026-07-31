module regfile #(
    parameter   XLEN=16,
    parameter   ADDR_WIDTH=4,
    localparam  REG_DEPTH=2**ADDR_WIDTH
) (
    input  logic [ADDR_WIDTH-1:0]   raddr_i,
    output logic [XLEN-1:0]         rdata_o,

    input  logic [ADDR_WIDTH-1:0]   waddr_i,
    input  logic [XLEN-1:0]         wdata_i,
    input  logic                    wen_i,

    input  logic                    clk
);
    logic [XLEN-1:0] memory [0:REG_DEPTH-1];

    always_ff @( posedge clk ) begin
        if(wen_i && waddr_i != 0) begin
            memory[waddr_i] <= wdata_i;
        end
    end

    assign rdata_o = memory[raddr_i];
endmodule
