module fir_top (
    // AXI-Stream Slave (Input)
    input   logic [15:0]    s_axis_tdata,
    input   logic           s_axis_tvalid,
    output  logic           s_axis_tready,
    
    // AXI-Stream Master (Output)
    output  logic [15:0]    m_axis_tdata,
    output  logic           m_axis_tvalid,
    input   logic           m_axis_tready,

    // Programming interface
    input   logic [7:0]     prog_data,
    input   logic           prog_valid,

    input   logic           arst_n,
    input   logic           clk
);
    /* FIR CONFIGURATION REGISTERS */
    logic [2:0]     config_delay_line;


    /* FIR PROGRAMMING DATAPATH */

    // new coefficient data
    logic           coeff_wr_en;
    logic [3:0]     coeff_wr_addr;
    logic [15:0]    coeff_wr_data;

    // integrate programming FSM


    /* FIR DATAPATH */

    // coefficient data
    logic [3:0]     coeff_rd_addr;
    logic [15:0]    coeff_rd_data;


    regfile coeff_regs (
        .raddr_i(coeff_rd_addr),
        .rdata_o(coeff_rd_data),

        .waddr_i(coeff_wr_addr),
        .wdata_i(coeff_wr_data),
        .wen_i(coeff_wr_en),

        .clk(clk)
    );

    // add delay line, MAC

    // integrate control FSM

endmodule
