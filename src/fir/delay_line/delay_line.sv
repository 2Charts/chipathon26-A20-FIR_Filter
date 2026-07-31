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

    //SIPO processing 16x16, 16x1, 16x15
    logic [15:0] sipo_top [1:16]; //Taps 31-16
    logic [15:0] sipo_mid;       //Center tap
    logic [15:0] sipo_bot [1:15]; //Taps 15-1

    //Explicit control signals decoding based on 3-bit mode_i
    logic mode_asym_active;
    logic mode_antisym_active;
    logic mode_odd_active;

    assign mode_asym_active=(mode_i[2] == 1'b0);
    assign mode_antisym_active=(mode_i[2] == 1'b1) && (mode_i[1] == 1'b1);
    assign mode_odd_active=(mode_i[2] == 1'b1) && (mode_i[0] == 1'b1);

    // SIPO shifting (Shift Register)
    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            for (int i=1; i<=16; i++) sipo_top[i]<=16'd0;
            sipo_mid <= 16'd0;
            for (int i=1; i<=15; i++) sipo_bot[i]<=16'd0;
        end
        else if (shift_en_i) begin
            //Shift top (16x16)
            sipo_top[1]<=sample_i;
            for (int i=2; i<=16; i++) sipo_top[i]<=sipo_top[i-1];
            
            //Shift mid (16x1)
            sipo_mid<=sipo_top[16];

            //Shift bottom (16x15)
            if (mode_odd_active == 1'b1) begin
                sipo_bot[1]<=sipo_mid; //If odd, take from mid
            end else begin
                sipo_bot[1]<=sipo_top[16]; //If even, straight from top
            end
            
            //Shifting for bottom
            for (int i=2; i<=15; i++) sipo_bot[i]<=sipo_bot[i-1];
        end
    end

    //16:1 Multiplexer logic part
    logic [15:0] mux_top;
    logic [15:0] mux_bot;
    logic [15:0] mux_bot_routed;

    always_comb begin
        //Top MUX (Taps 31-16)
        mux_top = sipo_top[16-sel_i]; 

        //Bottom MUX (Taps 15-1 and sample_i)
        if (sel_i == 4'd15) begin
            mux_bot = sample_i;
        end else begin
            mux_bot = sipo_bot[15-sel_i];
        end
        
        //Zeroing logic based on active modes
        if (mode_asym_active == 1'b1) begin
            //0xx: Asymmetric -> Drop ALL bottom data (A + 0)
            mux_bot_routed = 16'd0;
        end else if (mode_odd_active == 1'b1 && sel_i == 4'd15) begin
            //Odd mode -> Drop ONLY the center tap at sel_i=15
            mux_bot_routed=16'd0;
        end else begin
            //Normal symmetric / antisymmetric routing
            mux_bot_routed=mux_bot;
        end
    end

    //Pre-adder execution with clean Sign-Extension
    logic signed [16:0] top_ext;
    logic signed [16:0] bot_ext;

    always_comb begin
        //Sign extend 16-bit to 18-bit signed
        top_ext=$signed(mux_top);
        
        if (mode_antisym_active == 1'b1) begin
            //Subtraction (A - B) using direct signed arithmetic
            bot_ext=-$signed(mux_bot_routed);
        end else begin
            //Addition (A + B)
            bot_ext=$signed(mux_bot_routed);
        end
    end

    assign sample_o=top_ext + bot_ext;

endmodule