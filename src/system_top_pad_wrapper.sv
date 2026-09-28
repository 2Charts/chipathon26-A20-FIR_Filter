module system_top_pad_wrapper (
    input logic clk,
    output logic clk_PU,
    output logic clk_PD,

    input logic rst_n,
    output logic rst_n_PU,
    output logic rst_n_PD,

    input logic sck,
    output logic sck_PU,
    output logic sck_PD,

    input logic cs_n,
    output logic cs_n_PU,
    output logic cs_n_PD,

    input logic mosi,
    output logic mosi_PU,
    output logic mosi_PD,

    output logic miso_CS,
    output logic miso_SL,
    output logic miso_IE,
    output logic miso_oe,
    output logic miso_PU,
    output logic miso_PD,
    output logic miso_OUT,
    input logic miso_IN,

    input logic uart_rx,
    output logic uart_rx_PU,
    output logic uart_rx_PD

`ifdef USE_POWER_PINS
    , inout wire VDD,
    inout wire VSS
`endif
);

    // Tie-offs for unused pad controls
    assign clk_PU = 1'b0;
    assign clk_PD = 1'b0;

    assign rst_n_PU = 1'b0;
    assign rst_n_PD = 1'b0;

    assign sck_PU = 1'b0;
    assign sck_PD = 1'b0;

    assign cs_n_PU = 1'b0;
    assign cs_n_PD = 1'b0;

    assign mosi_PU = 1'b0;
    assign mosi_PD = 1'b0;

    assign miso_CS = 1'b0;
    assign miso_SL = 1'b0;
    assign miso_IE = 1'b0;
    assign miso_PU = 1'b0;
    assign miso_PD = 1'b0;

    assign uart_rx_PU = 1'b0;
    assign uart_rx_PD = 1'b0;

    system_top core (
        .clk(clk),
        .rst_n(rst_n),
        .sck(sck),
        .cs_n(cs_n),
        .mosi(mosi),
        .miso(miso_OUT),
        .miso_oe(miso_oe),
        .uart_rx(uart_rx)
`ifdef USE_POWER_PINS
        , .VDD(VDD),
        .VSS(VSS)
`endif
    );

endmodule
