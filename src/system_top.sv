module system_top (
    input logic clk,
    input logic rst_n,
    
    // spi interface
    input logic sck,
    input logic cs_n,
    input logic mosi,
    output logic miso,
    
    // uart for config
    input logic uart_rx
);

    // some basic params
    localparam SPI_DATA_WIDTH = 16;
    localparam FIFO_DEPTH = 8;
    localparam CLKS_PER_BIT = 434; // standard 
    
    // uart to config regs
    logic [15:0] coeff_data;
    logic [3:0] coeff_addr;
    logic [3:0] filter_mode;
    logic coeff_valid;
    
    // config regs to datapath
    logic [255:0] coeff_mem_flat;
    logic mode_odd;
    logic mode_asym;
    
    // axi stream between spi and fir controller
    logic [15:0] spi_to_fir_tdata;
    logic spi_to_fir_tvalid;
    logic spi_to_fir_tready;
    
    logic [15:0] fir_to_spi_tdata;
    logic fir_to_spi_tvalid;
    logic fir_to_spi_tready;
    
    // delay line wires
    logic shift_en;
    logic [3:0] sel;
    logic [15:0] data_in;
    logic [17:0] pre_adder_out;
    
    // mac wires
    logic mac_valid;
    logic mac_clear;
    logic signed [15:0] mac_x;
    logic signed [15:0] mac_c;
    logic signed [15:0] mac_y;
    
    // uart receiver
    uart_rx_coeff_loader #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uart_inst (
        .clk(clk),
        .rst(~rst_n), // uart uses active high reset!
        .rx_serial(uart_rx),
        .coeff_data(coeff_data),
        .coeff_addr(coeff_addr),
        .filter_mode(filter_mode),
        .coeff_valid(coeff_valid)
    );
    
    // holds the coefficients
    fir_config_regs config_inst (
        .clk(clk),
        .rst_n(rst_n),
        .coeff_data(coeff_data),
        .coeff_addr(coeff_addr),
        .filter_mode(filter_mode),
        .coeff_valid(coeff_valid),
        .coeff_mem_flat(coeff_mem_flat),
        .mode_odd(mode_odd),
        .mode_asym(mode_asym)
    );
    
    // state machine that runs the fir
    fir_controller controller_inst (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis_tdata(spi_to_fir_tdata),
        .s_axis_tvalid(spi_to_fir_tvalid),
        .s_axis_tready(spi_to_fir_tready),
        .m_axis_tdata(fir_to_spi_tdata),
        .m_axis_tvalid(fir_to_spi_tvalid),
        .m_axis_tready(fir_to_spi_tready),
        .shift_en(shift_en),
        .sel(sel),
        .data_in(data_in),
        .pre_adder_out(pre_adder_out),
        .mac_valid(mac_valid),
        .mac_clear(mac_clear),
        
        .mac_x(mac_x),
        .mac_c(mac_c),
        .mac_y(mac_y),
        .coeff_mem_flat(coeff_mem_flat)
    );
    
    // the folded delay line
    delay_line delay_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .pre_adder_out(pre_adder_out),
        .shift_en(shift_en),
        .sel(sel),
        .mode_odd(mode_odd),
        .mode_asym(mode_asym)
    );
    
    // mac engine
    mac mac_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid(mac_valid),
        .clear(mac_clear),
        .x(mac_x),
        .c(mac_c),
        .y(mac_y),
        .done()
    );
    
    // our AXI wrapped spi slave
    spi_axi_top #(
        .DATA_WIDTH(SPI_DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) spi_inst (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis_tdata(fir_to_spi_tdata),
        .s_axis_tvalid(fir_to_spi_tvalid),
        .s_axis_tready(fir_to_spi_tready),
        .m_axis_tdata(spi_to_fir_tdata),
        .m_axis_tvalid(spi_to_fir_tvalid),
        .m_axis_tready(spi_to_fir_tready),
        .sck(sck),
        .cs_n(cs_n),
        .mosi(mosi),
        .miso(miso)
    );

endmodule
