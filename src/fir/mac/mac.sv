module mac (
    input logic clk,
    input logic rst_n,
    input logic valid,
    input logic clear,
    input logic signed [16:0] x,
    input logic signed [15:0] c,

    output logic signed [15:0] y,
    output logic done
);

logic signed [32:0] product;
logic signed [36:0] accumulator;

logic signed [36:0] acc_rounded;
logic signed [21:0] acc_shifted;
logic signed [15:0] y_next;

assign acc_rounded = accumulator + 37'h4000; // Add 2^14 for rounding
assign acc_shifted = acc_rounded[36:15];     // shift right by 15

always_comb begin
    // saturation check to 16-bit signed clamping
    if (acc_shifted > 22'sd32767) begin
        y_next = 16'sd32767;
    end else if (acc_shifted < -22'sd32768) begin
        y_next = -16'sd32768;
    end else begin
        y_next = acc_shifted[15:0];
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        product <= '0;
        accumulator <= '0;
        y <= '0;
        done <= 1'b0;
    end else begin
        if (valid) begin
            product <= x * c;
            
            if (clear) begin
                accumulator <= 37'(product);
            end else begin
                accumulator <= accumulator + 37'(product);
            end
            
            y <= y_next;
            done <= 1'b1;
        end else begin
            done <= 1'b0;
        end
    end
end

endmodule