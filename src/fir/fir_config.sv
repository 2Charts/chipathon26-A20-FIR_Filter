module fir_config (
    input   logic [6:0] config_new_i,
    input   logic       config_write_i,

    output  logic [6:0] config_o,

    input   logic       rst_n,
    input   logic       clk
);

    logic [6:0] config_register;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            config_register <= 0;
        end
        else if (config_write_i) begin
            config_register <= config_new_i;
        end
    end

    assign config_o = config_register;

endmodule
