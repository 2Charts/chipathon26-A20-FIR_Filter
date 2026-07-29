module spi_axi_top #(
    parameter DATA_WIDTH = 16,
    parameter FIFO_DEPTH = 8
)(
    input logic clk,
    input logic rst_n,
    
    // axi stream from FIR to SPI
    input logic [DATA_WIDTH-1:0] s_axis_tdata,
    input logic s_axis_tvalid,
    output logic s_axis_tready,
    
    // axi stream from SPI to FIR
    output logic [DATA_WIDTH-1:0] m_axis_tdata,
    output logic m_axis_tvalid,
    input logic m_axis_tready,
    
    // SPI Slave pins
    input logic sck,
    input logic cs_n,
    input logic mosi,
    output logic miso
);

    logic tx_empty, tx_rd_en;
    logic [DATA_WIDTH-1:0] shift_din;
    
    logic rx_full, rx_wr_en;
    logic [DATA_WIDTH-1:0] shift_dout;
    
    logic tx_full;
    assign s_axis_tready = ~tx_full;
    
    // We use the dual clock fifo as a single clock FIFO by tying both clocks to clk
    dual_clock_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_DEPTH(FIFO_DEPTH)
    ) tx_fifo_inst (
        .rd_clk_i(clk),
        .rd_rst_n_i(rst_n),
        .rd_en_i(tx_rd_en),
        .rd_data_o(shift_din),
        .empty_o(tx_empty),
        .almost_empty_o(),
        .rd_count_o(),

        .wr_clk_i(clk),
        .wr_rst_n_i(rst_n),
        .wr_en_i(s_axis_tvalid && s_axis_tready),
        .wr_data_i(s_axis_tdata),
        .full_o(tx_full),
        .almost_full_o(),
        .wr_count_o()
    );
    
    logic rx_empty;
    assign m_axis_tvalid = ~rx_empty;
    
    dual_clock_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_DEPTH(FIFO_DEPTH)
    ) rx_fifo_inst (
        .rd_clk_i(clk),
        .rd_rst_n_i(rst_n),
        .rd_en_i(m_axis_tvalid && m_axis_tready),
        .rd_data_o(m_axis_tdata),
        .empty_o(rx_empty),
        .almost_empty_o(),
        .rd_count_o(),

        .wr_clk_i(clk),
        .wr_rst_n_i(rst_n),
        .wr_en_i(rx_wr_en && ~rx_full),
        .wr_data_i(shift_dout),
        .full_o(rx_full),
        .almost_full_o(),
        .wr_count_o()
    );
    
    spi_slave #(
        .DATA_WIDTH(DATA_WIDTH)
    ) slave_inst (
        .clk(clk),
        .rst_n(rst_n),
        
        .sck(sck),
        .cs_n(cs_n),
        .mosi(mosi),
        .miso(miso),
        
        .tx_data(shift_din),
        .tx_empty(tx_empty),
        .tx_rd_en(tx_rd_en),
        
        .rx_data(shift_dout),
        .rx_valid(rx_wr_en)
    );

endmodule
