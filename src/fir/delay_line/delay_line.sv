module delay_line (
    input  logic clk,
    input  logic arst_n,
    
    //Datapath part
    input  logic [15:0] sample_i, //Input sample
    output logic [16:0] sample_o, //Output from pre-adder

    //Controlpath part
    input  logic        shift_en_i,
    input  logic [3:0]  sel_i,    //For MUX sel_iector
    
    //Controlpath mode part (3-bit configuration)
    //Mode encoding:
    //0xx -> Asymmetric mode
    //100 -> Symmetric, Even
    //101 -> Symmetric, Odd
    //110 -> Anti-symmetric, Even
    //111 -> Anti-symmetric, Odd
    input  logic [2:0]  mode_i 
);

    //SIPO processing 16x16
    logic [15:0] sipo_top [1:16]; //Taps 1 to 16
    logic [15:0] sipo_bot [1:16]; //Taps 17 to 32

    //Explicit control signals decoding based on 3-bit mode_i
    logic mode_asym_active;
    logic mode_antisym_active;
    logic mode_odd_active;

    assign mode_asym_active = (mode_i[2] == 1'b0);
    assign mode_antisym_active = (mode_i[2] == 1'b1) && (mode_i[1] == 1'b1);
    assign mode_odd_active = (mode_i[2] == 1'b1) && (mode_i[0] == 1'b1);

    // SIPO shifting (Shift Register)
    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            for (int i=1; i<=16; i++) sipo_top[i] <= 16'd0;
            for (int i=1; i<=16; i++) sipo_bot[i] <= 16'd0;
        end
        else if (shift_en_i) begin
            //Shift top
            sipo_top[1] <= sample_i;
            for (int i=2; i<=16; i++) sipo_top[i] <= sipo_top[i-1];
            
            //Shift bottom
            sipo_bot[1] <= sipo_top[16];
            for (int i=2; i<=16; i++) sipo_bot[i] <= sipo_bot[i-1];
        end
    end

    //Multiplexer logic part
    logic [15:0] mux_top;
    logic [15:0] mux_bot;

    always_comb begin
        //Top MUX (Taps 1 to 16)
        mux_top = sipo_top[16 - sel_i]; 

        //Bottom MUX logic based on mode
        if (mode_asym_active == 1'b1) begin
            // Asymmetric mode: no bottom taps
            mux_bot = 16'd0;
        end else if (mode_odd_active == 1'b1) begin
            // Odd mode (31 taps): center tap is c[15] (sel_i == 0)
            if (sel_i == 4'd0) begin
                mux_bot = 16'd0;
            end else begin
                // Pair c[14] (sel_i=1) with sipo_bot[1] (x[t-16])
                // Pair c[0] (sel_i=15) with sipo_bot[15] (x[t-30])
                mux_bot = sipo_bot[sel_i];
            end
        end else begin
            // Even mode (32 taps):
            // Pair c[15] (sel_i=0) with sipo_bot[1] (x[t-16])
            // Pair c[0] (sel_i=15) with sipo_bot[16] (x[t-31])
            mux_bot = sipo_bot[sel_i + 1];
        end
    end

    //Pre-adder execution with clean Sign-Extension
    logic signed [16:0] top_ext;
    logic signed [16:0] bot_ext;

    always_comb begin
        //Sign extend 16-bit to 17-bit signed
        top_ext = $signed(mux_top);
        
        if (mode_antisym_active == 1'b1) begin
            //Subtraction (A - B) using direct signed arithmetic
            bot_ext = -$signed(mux_bot);
        end else begin
            //Addition (A + B)
            bot_ext = $signed(mux_bot);
        end
    end

    assign sample_o = top_ext + bot_ext;

endmodule