module programmer #(
    //module parameters (No default values, must be configured dynamically from outside)
    parameter int CLK_FREQ,
    parameter int BAUD_RATE,
    parameter int TIMEOUT_MS
)(
    input  logic        clk,
    input  logic        arst_n,
    
    //UART Input
    input  logic        rx_line_i,

    //Interface to fir_top (Configuration Register)
    output logic [6:0]  config_data_o,
    output logic        config_wr_en_o,

    //Interface to fir_top (Coefficient Register File)
    output logic [15:0] coeff_data_o,
    output logic [3:0]  coeff_addr_o,
    output logic        coeff_wr_en_o
);

    // TIMEOUT CALCULATION (Dynamic Width based on Parameters)
    localparam int TIMEOUT_CYCLES = (CLK_FREQ / 1000) * TIMEOUT_MS; 
    localparam int COUNTER_WIDTH  = $clog2(TIMEOUT_CYCLES + 1);

    // INTERNAL SIGNALS
    logic [7:0] uart_data_out;
    logic       uart_data_valid;

    logic [7:0] fifo_rd_data;
    logic       fifo_empty;
    logic       fifo_full;
    logic       fifo_rd_en;

    // Timer register timeout dengan lebar bit dinamis
    logic [COUNTER_WIDTH-1:0] timeout_cnt;

    // SUB-MODULE INSTANTIATIONS
    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) 
    u_uart_rx (
        .clk         (clk),
        .arst_n      (arst_n),
        .rx_line_i   (rx_line_i),
        .data_o      (uart_data_out),
        .data_valid_o(uart_data_valid)
    );

    fwft_fifo #(
        .DATA_WIDTH(8),
        .DATA_DEPTH(2)
    ) 
    u_fifo (
        .clk        (clk),
        .arst_n     (arst_n),
        .wr_en_i    (uart_data_valid),
        .wr_data_i  (uart_data_out),
        .rd_en_i    (fifo_rd_en),
        .rd_data_o  (fifo_rd_data),
        .empty_o    (fifo_empty),
        .full_o     (fifo_full)
    );

    //FSM PART
    typedef enum logic [1:0] {
        ST_IDLE      = 2'b00,
        ST_COEF_LOW  = 2'b01,
        ST_COEF_HIGH = 2'b10
    } state_t;

    state_t state, next_state;

    logic [3:0] saved_addr;
    logic [7:0] saved_low_byte;

    //Sequential Logic (State transition, data storage, & timeout counter)
    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            state          <= ST_IDLE;
            saved_addr     <= 4'd0;
            saved_low_byte <= 8'd0;
            timeout_cnt    <= '0;
            state <= next_state;

            //Timeout Logic
            if (state == ST_IDLE || (!fifo_empty && fifo_rd_en)) begin
                //Reset stopwatch if idle or just received data
                timeout_cnt <= '0;
            end else if (state != ST_IDLE) begin
                //Stopwatch runs if stuck in non-idle state
                timeout_cnt <= timeout_cnt + 1'b1;
            end

            //Store data logic
            if (!fifo_empty && fifo_rd_en) begin
                if (state == ST_IDLE && fifo_rd_data[7] == 1'b0) begin
                    saved_addr <= fifo_rd_data[3:0];
                end else if (state == ST_COEF_LOW) begin
                    saved_low_byte <= fifo_rd_data;
                end
            end
        end
    end

    //Combinational Logic (Next state and output evaluation)
    always_comb begin
        next_state     = state;
        fifo_rd_en     = 1'b0;
        
        config_data_o  = 7'd0;
        config_wr_en_o = 1'b0;
        
        coeff_data_o   = 16'd0;
        coeff_addr_o   = saved_addr;
        coeff_wr_en_o  = 1'b0;

        case (state)
            ST_IDLE: begin
                if (!fifo_empty) begin
                    fifo_rd_en = 1'b1;
                    
                    if (fifo_rd_data[7] == 1'b1) begin
                        config_data_o  = fifo_rd_data[6:0];
                        config_wr_en_o = 1'b1;
                        next_state     = ST_IDLE;
                    end else begin
                        next_state = ST_COEF_LOW;
                    end
                end
            end

            ST_COEF_LOW: begin
                if (!fifo_empty) begin
                    fifo_rd_en = 1'b1;
                    next_state = ST_COEF_HIGH;
                end else if (timeout_cnt >= TIMEOUT_CYCLES) begin
                    //Reset to idle if it takes too long
                    next_state = ST_IDLE;
                end
            end

            ST_COEF_HIGH: begin
                if (!fifo_empty) begin
                    fifo_rd_en    = 1'b1;
                    coeff_data_o  = {fifo_rd_data, saved_low_byte};
                    coeff_wr_en_o = 1'b1;
                    next_state    = ST_IDLE;
                end else if (timeout_cnt >= TIMEOUT_CYCLES) begin
                    //Reset to idle if it takes too long
                    next_state = ST_IDLE;
                end
            end
            
            default: next_state = ST_IDLE;
        endcase
    end

endmodule