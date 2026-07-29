module delay_line (
    input  logic clk,
    input  logic rst_n,
    
    //datapath part
    input  logic [15:0] data_in, //input sample
    output logic [17:0] pre_adder_out, //output from pre-adder

    //controlpath part
    input  logic        shift_en,
    input  logic [3:0]  sel, //for MUX selector
    
    //controlpath mode part
    input  logic        mode_odd, //1:odd, 0:even
    input  logic        mode_asym //1:Asy, 0:sym
);

    logic signed [15:0] shift_reg [0:31];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i=0; i<32; i++) begin
                shift_reg[i] <= 16'd0;
            end
        end else if (shift_en) begin
            shift_reg[0] <= data_in;
            for (int i=1; i<32; i++) begin
                shift_reg[i] <= shift_reg[i-1];
            end
        end
    end

    logic [4:0] idx1, idx2;
    assign idx1 = 15 - sel;
    assign idx2 = 16 + sel;
    
    logic signed [15:0] bot_val;
    always_comb begin
        if (mode_odd && sel == 4'd0) begin
            bot_val = 16'd0; // Center tap has no pair
        end else begin
            bot_val = shift_reg[idx2];
        end
    end
    
    logic signed [15:0] bot_routed;
    always_comb begin
        if (mode_asym) begin
            bot_routed = -bot_val;
        end else begin
            bot_routed = bot_val;
        end
    end
    
    assign pre_adder_out = shift_reg[idx1] + bot_routed;

endmodule