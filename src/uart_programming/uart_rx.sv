module uart_rx #(
    parameter CLK_FREQ  = 50_000_000,  // Default clock frequency (e.g., 50 MHz)
    parameter BAUD_RATE = 115200       // Default baud rate
)(
    input  wire       clk,
    input  wire       arst_n,
    input  wire       rx_line_i,
    output reg [7:0]  data_o,
    output reg        data_valid_o
);

    // Calculate the division factor for 16x oversampling
    localparam C_RX_DIV = CLK_FREQ / (BAUD_RATE * 16);

    reg [31:0] rx_baud_counter;
    reg        rx_baud_tick;

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            rx_baud_counter <= 0;
            rx_baud_tick    <= 1'b0;
        end else begin
            if (rx_baud_counter >= C_RX_DIV - 1) begin
                rx_baud_counter <= 0;
                rx_baud_tick    <= 1'b1;
            end else begin
                rx_baud_counter <= rx_baud_counter + 1;
                rx_baud_tick    <= 1'b0;
            end
        end
    end

    // Fast clock domain synchronizer for the asynchronous rx_line_i
    reg [1:0] rx_sync_sr;
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            rx_sync_sr <= 2'b11;
        end else begin
            rx_sync_sr[0] <= rx_line_i;
            rx_sync_sr[1] <= rx_sync_sr[0];
        end
    end

    // Slow baud-tick domain shift register for edge detection
    reg [1:0] uart_rx_data_sr;
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            uart_rx_data_sr <= 2'b11;
        end else begin
            if (rx_baud_tick) begin
                uart_rx_data_sr[0] <= rx_sync_sr[1];
                uart_rx_data_sr[1] <= uart_rx_data_sr[0];
            end
        end
    end

    reg [1:0] uart_rx_filter;
    reg       uart_rx_bit;

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            uart_rx_filter <= 2'b11;
            uart_rx_bit    <= 1'b1;
        end else begin
            if (rx_baud_tick) begin
                if (uart_rx_data_sr[1] == 1'b1 && uart_rx_filter < 3) begin
                    uart_rx_filter <= uart_rx_filter + 1;
                end else if (uart_rx_data_sr[1] == 1'b0 && uart_rx_filter > 0) begin
                    uart_rx_filter <= uart_rx_filter - 1;
                end

                if (uart_rx_filter == 2'd3) begin
                    uart_rx_bit <= 1'b1;
                end else if (uart_rx_filter == 2'd0) begin
                    uart_rx_bit <= 1'b0;
                end
            end
        end
    end

    localparam ST_RX_START = 2'b00;
    localparam ST_RX_DATA  = 2'b01;
    localparam ST_RX_STOP  = 2'b10;

    reg [1:0] uart_rx_state;
    reg [3:0] uart_rx_bit_spacing;
    reg [2:0] uart_rx_count;

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            uart_rx_state       <= ST_RX_START;
            uart_rx_bit_spacing <= 0;
            uart_rx_count       <= 0;
            data_o           <= 8'h00;
            data_valid_o          <= 1'b0;
        end else begin
            data_valid_o <= 1'b0;

            if (rx_baud_tick) begin
                case (uart_rx_state)
                    ST_RX_START: begin
                        if (uart_rx_bit == 1'b0) begin
                            // PENTING: Tunggu 7 tick (setengah bit) biar pas di tengah mata sinyal
                            if (uart_rx_bit_spacing == 7) begin
                                uart_rx_state       <= ST_RX_DATA;
                                uart_rx_bit_spacing <= 0;
                                uart_rx_count       <= 0;
                            end else begin
                                uart_rx_bit_spacing <= uart_rx_bit_spacing + 1;
                            end
                        end else begin
                            uart_rx_bit_spacing <= 0;
                        end
                    end

                    ST_RX_DATA: begin
                        // Tunggu 15 tick (1 bit penuh) untuk baca bit berikutnya
                        if (uart_rx_bit_spacing == 15) begin
                            uart_rx_bit_spacing <= 0;
                            data_o <= {uart_rx_bit, data_o[7:1]};
                            
                            if (uart_rx_count < 7) begin
                                uart_rx_count <= uart_rx_count + 1;
                            end else begin
                                uart_rx_count <= 0;
                                uart_rx_state <= ST_RX_STOP;
                            end
                        end else begin
                            uart_rx_bit_spacing <= uart_rx_bit_spacing + 1;
                        end
                    end

                    ST_RX_STOP: begin
                        if (uart_rx_bit_spacing == 15) begin
                            uart_rx_bit_spacing <= 0;
                            if (uart_rx_bit == 1'b1) begin 
                                data_valid_o <= 1'b1; 
                            end
                            uart_rx_state <= ST_RX_START;
                        end else begin
                            uart_rx_bit_spacing <= uart_rx_bit_spacing + 1;
                        end
                    end
                    
                    default: uart_rx_state <= ST_RX_START;
                endcase
            end
        end
    end

endmodule
