module system_top # (
    // some basic params
    parameter int CLK_FREQ = 16_000_000,
    parameter int BAUD_RATE = 115200
)(
    input logic clk,
    input logic rst_n,
    
    // spi interface
    input logic sck,
    input logic cs_n,
    input logic mosi,
    output logic miso,
    output logic miso_oe,
    
    // uart for config
    input logic uart_rx
);

    localparam FIFO_DEPTH = 8;
    
    // Reset Synchronizer
    logic rst_n_meta;
    logic rst_n_sync;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_n_meta <= 1'b0;
            rst_n_sync <= 1'b0;
        end else begin
            rst_n_meta <= 1'b1;
            rst_n_sync <= rst_n_meta;
        end
    end
    
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
        .arst_n(rst_n_sync),
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
        
        .arst_n(rst_n_sync),
        .clk(clk)
    );
    
    // AXI wrapped spi slave
    spi_axis_top #(
        .FIFO_DEPTH(FIFO_DEPTH)
    ) spi_inst (
        .clk(clk),
        .arst_n(rst_n_sync),
        
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
        .miso_o(miso),
        .miso_oe_o(miso_oe)
    );

endmodule
