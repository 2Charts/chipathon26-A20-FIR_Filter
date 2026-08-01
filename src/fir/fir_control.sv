module fir_control (
    input  logic        clk,
    input  logic        arst_n,

    // AXI-Stream Slave (Input)
    input  logic        s_axis_tvalid_i,
    output logic        s_axis_tready_o,

    // AXI-Stream Master (Output)
    output logic        m_axis_tvalid_o,
    input  logic        m_axis_tready_i,

    // Datapath Control
    output logic        delay_line_shift_o,
    output logic [3:0]  delay_line_sel_o,
    output logic [3:0]  coeff_rd_addr_o,
    output logic        mac_enable_o,
    output logic        mac_clear_o
);

    typedef enum logic [1:0] {
        FETCH,
        LOOP,
        WRITE
    } state_t;

    state_t state, next_state;
    logic [4:0] cnt;

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            state <= FETCH;
            cnt   <= '0;
        end else begin
            state <= next_state;
            if (state != LOOP) begin
                cnt <= '0;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end
    end

    always_comb begin
        next_state         = state;

        s_axis_tready_o    = 1'b0;
        m_axis_tvalid_o    = 1'b0;

        delay_line_shift_o = 1'b0;
        delay_line_sel_o   = 4'd0;
        coeff_rd_addr_o    = 4'd0;
        mac_enable_o       = 1'b0;
        mac_clear_o        = 1'b0;

        case (state)
            FETCH: begin
                s_axis_tready_o = 1'b1;
                if (s_axis_tvalid_i) begin
                    delay_line_shift_o = 1'b1;
                    next_state = LOOP;
                end
            end

            LOOP: begin
                mac_enable_o = 1'b1;
                
                // Keep index at 15 if cnt goes beyond 15, to avoid out-of-bounds or wrap around
                coeff_rd_addr_o  = (cnt < 5'd16) ? cnt[3:0] : 4'd15;
                delay_line_sel_o = (cnt < 5'd16) ? cnt[3:0] : 4'd15;
                
                if (cnt == 5'd1) begin
                    mac_clear_o = 1'b1;
                end

                // Need to wait until cnt == 17 to allow the last accumulation and result rounding to propagate
                if (cnt == 5'd17) begin
                    next_state = WRITE;
                end
            end

            WRITE: begin
                m_axis_tvalid_o = 1'b1;
                
                if (m_axis_tready_i) begin
                    next_state = FETCH;
                end
            end
            
            default: begin
                next_state = FETCH;
            end
        endcase
    end

endmodule
