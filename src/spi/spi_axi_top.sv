module spi_axi_top #(
    parameter DATA_WIDTH = 16,
    parameter FIFO_DEPTH = 8
)(
    // AXI Stream slave input
    input   logic [DATA_WIDTH-1:0]  s_axis_tdata_i,
    input   logic                   s_axis_tvalid_i,
    output  logic                   s_axis_tready_o,
    
    // AXI Stream master output
    output  logic [DATA_WIDTH-1:0]  m_axis_tdata_o,
    output  logic                   m_axis_tvalid_o,
    input   logic                   m_axis_tready_i,
    
    // SPI pins
    input   logic                   sck_i,
    input   logic                   cs_n_i,
    input   logic                   mosi_i,
    output  logic                   miso_o,

    input   logic                   rst_n,
    input   logic                   clk
);

endmodule
