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

    logic [2:0]     delay_line_sel;
    assign delay_line_sel = config_register[6:4];

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
    logic [3:0]     coeff_rd_addr;
    logic [15:0]    coeff_rd_data;


    regfile coeff_regs (
        .raddr_i(coeff_rd_addr),
        .rdata_o(coeff_rd_data),

        .waddr_i(coeff_addr_i),
        .wdata_i(coeff_data_i),
        .wen_i(coeff_wr_en),

        .clk(clk)
    );

    // delay_line delay_line (
    // input  logic clk,
    // input  logic arst_n,
    
    // // Datapath part
    // input  logic [15:0] sample_i,         // Input sample
    // output logic [17:0] sample_o,         // Output from pre-adder

    // // Controlpath part
    // input  logic        shift_en_i,
    // input  logic [3:0]  sel_i,             // For MUX sel_iector
    
    // // Controlpath mode part (3-bit configuration)
    // // Mode encoding:
    // // 0xx -> Asymmetric mode
    // // 100 -> Symmetric, Even
    // // 101 -> Symmetric, Odd
    // // 110 -> Anti-symmetric, Even
    // // 111 -> Anti-symmetric, Odd
    // input  logic [2:0]  mode_i 
    // );

    // add delay line, MAC

    // integrate control FSM

endmodule
