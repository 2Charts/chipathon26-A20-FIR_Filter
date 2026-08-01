module fir_top (
    // AXI-Stream Slave (Input)
    input   logic [15:0]    s_axis_tdata_i,
    input   logic           s_axis_tvalid_i,
    output  logic           s_axis_tready_o,
    
    // AXI-Stream Master (Output)
    output  logic [15:0]    m_axis_tdata_o,
    output  logic           m_axis_tvalid_o,
    input   logic           m_axis_tready_i,

    // Registers interface
    // 7-bit config register
    input   logic [6:0]     config_data_i,
    input   logic           config_wr_en_i,
    // 16 x 16-bit coefficient registers
    input   logic [15:0]    coeff_data_i,
    input   logic [3:0]     coeff_addr_i,
    input   logic           coeff_wr_en_i,

    input   logic           arst_n,
    input   logic           clk
);
    /* FIR CONFIGURATION REGISTER */

    // 7 bit config Register
    // MSB [ D D D R R R R ] LSB
    // D : Delay Line Mux
    // R : Reserved
    logic [6:0]     config_register;

    logic [2:0]     delay_line_mode;
    assign delay_line_mode = config_register[6:4];

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            config_register <= 0;
        end
        else if (config_wr_en_i) begin
            config_register <= config_data_i;
        end
    end

    /* FIR DATAPATH */

    // coefficient data
    logic [3:0]     coeff_rd_addr; // control
    logic [15:0]    coeff_rd_data;

    logic [16:0]    mac_data_input;
    logic           delay_line_shift;   // control
    logic [3:0]     delay_line_sel;     // control
    logic           mac_enable;         // control
    logic           mac_clear;         // control

    regfile coeff_regs (
        .raddr_i(coeff_rd_addr),
        .rdata_o(coeff_rd_data),

        .waddr_i(coeff_addr_i),
        .wdata_i(coeff_data_i),
        .wen_i(coeff_wr_en),

        .clk(clk)
    );

    delay_line delay_line (
        .clk(clk),
        .arst_n(arst_n),

        .sample_i(s_axis_tdata_i),
        .sample_o(mac_data_input),

        .shift_en_i(delay_line_shift),
        .sel_i(delay_line_sel),
        
        .mode_i(delay_line_mode)
    );

    mac mac (
        .clk(clk),
        .arst_n(arst_n),
        .enable_i(mac_enable),
        .clear_i(mac_clear),
        .sample_i(mac_data_input),
        .coeff_i(coeff_rd_data),
        .result_o(m_axis_tdata_o)
    );

    fir_control control (
        .clk(clk),
        .arst_n(arst_n),
        
        .s_axis_tvalid_i(s_axis_tvalid_i),
        .s_axis_tready_o(s_axis_tready_o),
        
        .m_axis_tvalid_o(m_axis_tvalid_o),
        .m_axis_tready_i(m_axis_tready_i),
        
        .delay_line_shift_o(delay_line_shift),
        .delay_line_sel_o(delay_line_sel),
        .coeff_rd_addr_o(coeff_rd_addr),
        .mac_enable_o(mac_enable),
        .mac_clear_o(mac_clear)
    );

endmodule
