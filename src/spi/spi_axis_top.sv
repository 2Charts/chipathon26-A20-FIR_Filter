module spi_axis_top #(
    parameter FIFO_DEPTH = 8
)(
    // AXI Stream slave input
    input   logic [15:0]    s_axis_tdata_i,
    input   logic           s_axis_tvalid_i,
    output  logic           s_axis_tready_o,
    
    // AXI Stream master output
    output  logic [15:0]    m_axis_tdata_o,
    output  logic           m_axis_tvalid_o,
    input   logic           m_axis_tready_i,
    
    // SPI pins
    input   logic           sck_i,
    input   logic           cs_n_i,
    input   logic           mosi_i,
    output  logic           miso_o,

    input   logic           rst_n,
    input   logic           clk
);
    logic [15:0] rx_data;
    logic rx_wr_en, rx_empty;

    assign m_axis_tvalid_o = ~rx_empty;

    fwft_fifo #( 
        .DATA_WIDTH(16), 
        .DATA_DEPTH(FIFO_DEPTH)
    ) fifo_rx (
        .rd_en_i(m_axis_tready_i && ~rx_empty),
        .rd_data_o(m_axis_tdata_o),

        .wr_en_i(rx_wr_en),
        .wr_data_i(rx_data),

        .empty_o(rx_empty),
        .full_o(),

        .rst_n(rst_n),
        .clk(clk)
    );

    logic [15:0] tx_data;
    logic tx_rd_en, tx_empty, tx_full;

    assign s_axis_tready_o = ~tx_full;

    fwft_fifo #( 
        .DATA_WIDTH(16),
        .DATA_DEPTH(FIFO_DEPTH)
    ) fifo_tx (
        .rd_en_i(tx_rd_en),
        .rd_data_o(tx_data),

        .wr_en_i(s_axis_tvalid_i && ~tx_full),
        .wr_data_i(s_axis_tdata_i),

        .empty_o(tx_empty),
        .full_o(tx_full),

        .rst_n(rst_n),
        .clk(clk)
    );

    spi_slave slave (
    // SPI pins
        .sck_i(sck_i),
        .cs_n_i(cs_n_i),
        .mosi_i(mosi_i),
        .miso_o(miso_o),

    // FWFT FIFO interface
        .tx_data_i(tx_data),
        .tx_empty_i(tx_empty),
        .tx_rd_en_o(tx_rd_en),

        .rx_data_o(rx_data),
        .rx_wr_en_o(rx_wr_en),

        .rst_n(rst_n),
        .clk(clk)
    );

endmodule
