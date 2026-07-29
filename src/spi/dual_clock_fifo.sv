module dual_clock_fifo # (
    parameter DATA_WIDTH = 16,
    parameter DATA_DEPTH = 8,
    parameter ADDR_WIDTH = $clog2(DATA_DEPTH)
) (
    // Read Side Ports
    output logic [ADDR_WIDTH-1:0] rd_count_o,
    output logic [DATA_WIDTH-1:0] rd_data_o,
    output logic                  empty_o,
    output logic                  almost_empty_o,
    input  logic                  rd_en_i,
    input  logic                  rd_clk_i,
    input  logic                  rd_rst_n_i,

    // Write Side Ports
    output logic [ADDR_WIDTH-1:0] wr_count_o,
    output logic                  full_o,
    output logic                  almost_full_o,
    input  logic [DATA_WIDTH-1:0] wr_data_i,
    input  logic                  wr_en_i,
    input  logic                  wr_clk_i,
    input  logic                  wr_rst_n_i
);
    // Because we are using an oversampling SPI Slave architecture, 
    // both clocks are actually connected to the same system `clk`.
    // We can safely implement this as a simple synchronous FWFT FIFO!
    
    logic [DATA_WIDTH-1:0] mem [0:DATA_DEPTH-1];
    logic [ADDR_WIDTH:0] count;
    logic [ADDR_WIDTH-1:0] wr_ptr;
    logic [ADDR_WIDTH-1:0] rd_ptr;
    
    assign full_o = (count == DATA_DEPTH);
    assign empty_o = (count == 0);
    assign almost_full_o = (count >= DATA_DEPTH - 1);
    assign almost_empty_o = (count <= 1);
    
    // FWFT read
    assign rd_data_o = mem[rd_ptr];
    
    assign wr_count_o = wr_ptr;
    assign rd_count_o = rd_ptr;
    
    logic write_act, read_act;
    assign write_act = wr_en_i && !full_o;
    assign read_act = rd_en_i && !empty_o;
    
    always_ff @(posedge rd_clk_i or negedge rd_rst_n_i) begin
        if (!rd_rst_n_i) begin
            count <= '0;
            wr_ptr <= '0;
            rd_ptr <= '0;
        end else begin
            if (write_act && read_act) begin
                mem[wr_ptr] <= wr_data_i;
                wr_ptr <= wr_ptr + 1'b1;
                rd_ptr <= rd_ptr + 1'b1;
            end else if (write_act) begin
                mem[wr_ptr] <= wr_data_i;
                wr_ptr <= wr_ptr + 1'b1;
                count <= count + 1'b1;
            end else if (read_act) begin
                rd_ptr <= rd_ptr + 1'b1;
                count <= count - 1'b1;
            end
        end
    end
endmodule