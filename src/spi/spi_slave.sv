module spi_slave #(
    parameter DATA_WIDTH = 16
)(
    input logic clk,
    input logic rst_n,
    
    // SPI pins (asynchronous)
    input logic sck,
    input logic cs_n,
    input logic mosi,
    output logic miso,
    
    // Data interface (synchronous to clk)
    input logic [DATA_WIDTH-1:0] tx_data,
    input logic tx_empty,
    output logic tx_rd_en,
    
    output logic [DATA_WIDTH-1:0] rx_data,
    output logic rx_valid
);

    // 2-stage synchronizers
    logic [2:0] sck_sync;
    logic [2:0] cs_n_sync;
    logic [1:0] mosi_sync;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sck_sync <= 3'b0;
            cs_n_sync <= 3'b111; // cs_n is active low
            mosi_sync <= 2'b0;
        end else begin
            sck_sync <= {sck_sync[1:0], sck};
            cs_n_sync <= {cs_n_sync[1:0], cs_n};
            mosi_sync <= {mosi_sync[0], mosi};
        end
    end
    
    // Edge detectors
    logic sck_rise;
    logic sck_fall;
    logic cs_n_fall;
    logic cs_n_active;
    
    assign sck_rise = (sck_sync[2:1] == 2'b01);
    assign sck_fall = (sck_sync[2:1] == 2'b10);
    assign cs_n_fall = (cs_n_sync[2:1] == 2'b10);
    assign cs_n_active = ~cs_n_sync[1];
    
    // Shift registers
    logic [DATA_WIDTH-1:0] tx_shift_reg;
    logic [DATA_WIDTH-1:0] rx_shift_reg;
    logic [4:0] bit_cnt;
    
    // MISO is driven by the MSB of the tx_shift_reg
    // Only drive MISO when CS is low, otherwise high-Z (or just 0 if no tristate allowed internally)
    // Here we will just drive it to 0 when inactive, top level pads will handle tristate if needed.
    assign miso = cs_n_active ? tx_shift_reg[DATA_WIDTH-1] : 1'b0;
    
    assign rx_data = rx_shift_reg;
    
    logic rx_valid_done;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift_reg <= '0;
            rx_shift_reg <= '0;
            bit_cnt <= '0;
            rx_valid <= 1'b0;
            tx_rd_en <= 1'b0;
            rx_valid_done <= 1'b0;
        end else begin
            // Default pulldowns for 1-cycle pulses
            rx_valid <= 1'b0;
            tx_rd_en <= 1'b0;
            
            if (cs_n_fall) begin
                // Load transmit data
                if (!tx_empty) begin
                    tx_shift_reg <= tx_data;
                    tx_rd_en <= 1'b1; // acknowledge read from FIFO
                end else begin
                    tx_shift_reg <= '0; // shift out zeros if nothing to send
                end
                bit_cnt <= '0;
                
            end else if (cs_n_active) begin
            
                if (sck_rise) begin
                    // Sample MOSI on rising edge
                    rx_shift_reg <= {rx_shift_reg[DATA_WIDTH-2:0], mosi_sync[1]};
                    bit_cnt <= bit_cnt + 1'b1;
                    
                    if (bit_cnt == DATA_WIDTH - 1) begin
                        rx_valid <= 1'b1;
                    end
                end
                
                if (sck_fall) begin
                    // Shift out next bit on falling edge
                    tx_shift_reg <= {tx_shift_reg[DATA_WIDTH-2:0], 1'b0};
                end
            end
        end
    end

endmodule
