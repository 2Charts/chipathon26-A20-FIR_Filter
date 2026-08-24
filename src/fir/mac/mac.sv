module mac (
    input logic clk,
    input logic arst_n,
    input logic enable_i,
    input logic clear_i,
    input logic signed [16:0] sample_i,
    input logic signed [15:0] coeff_i,

    output logic signed [15:0] result_o
);

// Pipeline registers
logic signed [16:0] sample_reg;
logic signed [15:0] coeff_reg;
logic enable_reg;
logic clear_reg;

logic signed [32:0] product;
logic signed [36:0] accumulator;

logic signed [36:0] acc_rounded;
logic signed [21:0] acc_shifted;
logic signed [15:0] result_next;

assign acc_rounded = accumulator + 37'h4000; // Add 2^14 for rounding
assign acc_shifted = acc_rounded[36:15];     // shift right by 15

always_comb begin
    // saturation check to 16-bit signed clamping
    if (acc_shifted > 22'sd32767) begin
        result_next = 16'sd32767;
    end else if (acc_shifted < -22'sd32768) begin
        result_next = -16'sd32768;
    end else begin
        result_next = acc_shifted[15:0];
    end
end

always_ff @(posedge clk or negedge arst_n) begin
    if (!arst_n) begin
        sample_reg <= '0;
        coeff_reg <= '0;
        enable_reg <= 1'b0;
        clear_reg <= 1'b0;
        product <= '0;
        accumulator <= '0;
        result_o <= '0;
    end else begin
        // Pipeline Stage 1: Register Inputs
        sample_reg <= sample_i;
        coeff_reg <= coeff_i;
        enable_reg <= enable_i;
        clear_reg <= clear_i;

        // Pipeline Stage 2 & 3: Multiply and Accumulate
        if (enable_reg) begin
            product <= sample_reg * coeff_reg;
            
            if (clear_reg) begin
                accumulator <= 37'(product);
            end else begin
                accumulator <= accumulator + 37'(product);
            end
            
            result_o <= result_next;
        end
    end
end

endmodule