module spi_slave #(
    parameter DATA_WIDTH = 16
)(
    // SPI pins
    input   logic                   sck_i,
    input   logic                   cs_n_i,
    input   logic                   mosi_i,
    output  logic                   miso_o,
    
    // FIFO interface
    input   logic [DATA_WIDTH-1:0]  tx_data_i,
    input   logic                   tx_empty_i,
    output  logic                   tx_rd_en_i,

    output  logic [DATA_WIDTH-1:0]  rx_data_i,
    output  logic                   rx_valid_i,

    input   logic rst_n,
    input   logic clk
);

endmodule
