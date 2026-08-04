module system_top (
    input logic clk,
    input logic rst_n,
    
    // spi interface
    input logic sck,
    input logic cs_n,
    input logic mosi,
    output logic miso,
    
    // uart for config
    input logic uart_rx,
    
    // data ready output for padring
    output logic data_ready
);

    // some basic params
    localparam SPI_DATA_WIDTH = 16;
    localparam FIFO_DEPTH = 8;
    localparam int CLK_FREQ = 50_000_000;
    localparam int BAUD_RATE = 115200;
    
    // config wires
    logic [6:0]  config_data;
    logic        config_wr_en;
    logic [15:0] coeff_data;
    logic [3:0]  coeff_addr;
    logic        coeff_wr_en;
    
    // axi stream between spi and fir
    logic [15:0] spi_to_fir_tdata;
    logic        spi_to_fir_tvalid;
    logic        spi_to_fir_tready;
    
    logic [15:0] fir_to_spi_tdata;
    logic        fir_to_spi_tvalid;
    logic        fir_to_spi_tready;
    
    // uart programmer
    programmer #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .TIMEOUT_MS(5)
    ) prog_inst (
        .clk(clk),
        .arst_n(rst_n),
        .rx_line_i(uart_rx),
        .config_data_o(config_data),
        .config_wr_en_o(config_wr_en),
        .coeff_data_o(coeff_data),
        .coeff_addr_o(coeff_addr),
        .coeff_wr_en_o(coeff_wr_en)
    );
    
    // FIR subsystem
    fir_top fir_inst (
        .s_axis_tdata_i(spi_to_fir_tdata),
        .s_axis_tvalid_i(spi_to_fir_tvalid),
        .s_axis_tready_o(spi_to_fir_tready),
        
        .m_axis_tdata_o(fir_to_spi_tdata),
        .m_axis_tvalid_o(fir_to_spi_tvalid),
        .m_axis_tready_i(fir_to_spi_tready),
        
        .config_data_i(config_data),
        .config_wr_en_i(config_wr_en),
        .coeff_data_i(coeff_data),
        .coeff_addr_i(coeff_addr),
        .coeff_wr_en_i(coeff_wr_en),
        
        .arst_n(rst_n),
        .clk(clk)
    );
    
    // monitor signal for padring
    assign data_ready = fir_to_spi_tvalid;
    
    // AXI wrapped spi slave
    spi_axis_top #(
        .FIFO_DEPTH(FIFO_DEPTH)
    ) spi_inst (
        .clk(clk),
        .arst_n(rst_n),
        
        // Data coming INTO the SPI from the FIR
        .s_axis_tdata_i(fir_to_spi_tdata),
        .s_axis_tvalid_i(fir_to_spi_tvalid),
        .s_axis_tready_o(fir_to_spi_tready),
        
        // Data going OUT of the SPI to the FIR
        .m_axis_tdata_o(spi_to_fir_tdata),
        .m_axis_tvalid_o(spi_to_fir_tvalid),
        .m_axis_tready_i(spi_to_fir_tready),
        
        .sck_i(sck),
        .cs_n_i(cs_n),
        .mosi_i(mosi),
        .miso_o(miso)
    );

endmodule
