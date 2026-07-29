// SPDX-FileCopyrightText: 2026 Chipathon 2026 workshop
// SPDX-License-Identifier: Apache-2.0
//
// Minimal chip_core for the Chipathon 2026 workshop padring slot.
// The emphasis of this slot is the padring itself (60 analog + 20
// bidir + 4/4 power + clk/rst_n); the core is intentionally trivial:
// a free-running counter whose state drives the 20 bidir pads. The
// 60 analog pads are routed straight through to analog[] and stay
// unconnected at the core level (the intent is that a downstream
// design wires them to custom analog IP later).

`default_nettype none

module chip_core #(
    parameter NUM_INPUT_PADS,
    parameter NUM_BIDIR_PADS,
    parameter NUM_ANALOG_PADS
    )(
    `ifdef USE_POWER_PINS
    inout  wire VDD,
    inout  wire VSS,
    `endif

    input  wire clk,       // clock
    input  wire rst_n,     // reset (active low)

    input  wire [NUM_INPUT_PADS-1:0] input_in,   // Input value
    output wire [NUM_INPUT_PADS-1:0] input_pu,   // Pull-up
    output wire [NUM_INPUT_PADS-1:0] input_pd,   // Pull-down

    input  wire [NUM_BIDIR_PADS-1:0] bidir_in,   // Input value
    output wire [NUM_BIDIR_PADS-1:0] bidir_out,  // Output value
    output wire [NUM_BIDIR_PADS-1:0] bidir_oe,   // Output enable
    output wire [NUM_BIDIR_PADS-1:0] bidir_cs,   // Input type (0=CMOS, 1=Schmitt)
    output wire [NUM_BIDIR_PADS-1:0] bidir_sl,   // Slew rate (0=fast, 1=slow)
    output wire [NUM_BIDIR_PADS-1:0] bidir_ie,   // Input enable
    output wire [NUM_BIDIR_PADS-1:0] bidir_pu,   // Pull-up
    output wire [NUM_BIDIR_PADS-1:0] bidir_pd,   // Pull-down

    inout  wire [NUM_ANALOG_PADS-1:0] analog    // Analog
);

    // Disable pull-up and pull-down on any discrete input pads.
    assign input_pu = '0;
    assign input_pd = '0;

    wire uart_rx;
    wire mosi;
    wire miso;
    wire sck;
    wire cs_n;
    wire data_ready;

    // Map inputs to bidir_in
    // Pin 5: uart_rx (bidir 0)
    // Pin 6: mosi (bidir 1)
    // Pin 8: sck (bidir 3)
    // Pin 9: cs_n (bidir 4)
    assign uart_rx = bidir_in[0];
    assign mosi    = bidir_in[1];
    assign sck     = bidir_in[3];
    assign cs_n    = bidir_in[4];

    // Map outputs to bidir_out
    // Pin 7: miso (bidir 2)
    // Pin 10: data_ready (bidir 5)
    assign bidir_out[0] = 1'b0;
    assign bidir_out[1] = 1'b0;
    assign bidir_out[2] = miso;
    assign bidir_out[3] = 1'b0;
    assign bidir_out[4] = 1'b0;
    assign bidir_out[5] = data_ready;

    // Output enable: 1 for outputs, 0 for inputs
    assign bidir_oe[0] = 1'b0;
    assign bidir_oe[1] = 1'b0;
    assign bidir_oe[2] = 1'b1;
    assign bidir_oe[3] = 1'b0;
    assign bidir_oe[4] = 1'b0;
    assign bidir_oe[5] = 1'b1;

    // Tie off the remaining bidir pads
    genvar i;
    generate
        for (i = 6; i < NUM_BIDIR_PADS; i++) begin : gen_tie_off
            assign bidir_out[i] = 1'b0;
            assign bidir_oe[i]  = 1'b0;
        end
    endgenerate

    // Other bidir controls (common)
    assign bidir_cs = '0;
    assign bidir_sl = '0;
    assign bidir_ie = ~bidir_oe;
    assign bidir_pu = '0;
    assign bidir_pd = '0;

    system_top u_system_top (
        .clk(clk),
        .rst_n(rst_n),
        .sck(sck),
        .cs_n(cs_n),
        .mosi(mosi),
        .miso(miso),
        .uart_rx(uart_rx),
        .data_ready(data_ready)
    );

endmodule

`default_nettype wire
