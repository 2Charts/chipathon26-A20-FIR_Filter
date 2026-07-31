module spi_slave (
    // SPI pins
    input   logic           sck_i,
    input   logic           cs_n_i,
    input   logic           mosi_i,
    output  logic           miso_o,

    // FWFT FIFO interface
    input   logic [15:0]    tx_data_i,
    input   logic           tx_empty_i,
    output  logic           tx_rd_en_o,

    output  logic [15:0]    rx_data_o,
    output  logic           rx_wr_en_o,

    input   logic           arst_n,
    input   logic           clk
);
    /*
        SPI Slave Configuration
        - Mode 0 (sck idle low, sample on rising edge, transmit on falling edge)
        - MSB first bit order
        - 16-bit (2 byte) transactions
    */

    // input synchronizer + edge detector FF
    logic [2:0] sync_sck;
    logic [2:0] sync_cs_n;
    logic [1:0] sync_mosi;

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            sync_sck    <= 0;
            sync_cs_n   <= 0;
            sync_mosi   <= 0;
        end
        else begin
            sync_sck    <= {sync_sck[1:0], sck_i};
            sync_cs_n   <= {sync_cs_n[1:0], cs_n_i};
            sync_mosi   <= {sync_mosi[0], mosi_i};
        end
    end

    // SCK rising, falling edge
    logic sck_re;
    logic sck_fe;
    assign sck_re = (sync_sck[2:1] == 2'b01) ? 1'b1 : 1'b0;
    assign sck_fe = (sync_sck[2:1] == 2'b10) ? 1'b1 : 1'b0;

    // SPI start, end & active from CS signal
    logic spi_start;
    //logic spi_end;
    logic spi_active;
    assign spi_start  = (sync_cs_n[2:1] == 2'b10) ? 1'b1 : 1'b0; // start on CS falling edge
    //assign spi_end    = (sync_cs_n[2:1] == 2'b01) ? 1'b1 : 1'b0; // end on CS rising edge
    assign spi_active = ~sync_cs_n[1]; // SPI CS active low

    // clean SPI data lines
    logic mosi;
    logic miso;
    assign mosi   = sync_mosi[1];
    assign miso_o = spi_active ? miso : 1'bz;

    logic [15:0] sreg;
    logic [4:0]  bit_cnt;

    always_ff @(posedge clk or negedge arst_n) begin
        tx_rd_en_o <= 1'b0;
        rx_wr_en_o <= 1'b0;

        if (!arst_n) begin
            sreg    <= 0;
            miso    <= 0;
            bit_cnt <= 0;
        end
        else if (spi_start) begin
            bit_cnt <= 0;
            
            if (tx_empty_i) begin
                sreg <= 0;
                miso <= 0;
            end 
            else begin
                sreg <= tx_data_i;
                miso <= tx_data_i[15];
            end
        end
        else if (spi_active && sck_re) begin
            sreg <= {sreg[14:0], mosi};
            
            if (bit_cnt < 5'd16) begin
                bit_cnt <= bit_cnt + 5'd1;
            end

            if (bit_cnt == 5'd15) begin
                tx_rd_en_o <= 1'b1;
                rx_wr_en_o <= 1'b1;
            end
        end
        else if (spi_active && sck_fe) begin
            miso <= sreg[15];
        end
    end

    assign rx_data_o = sreg;

endmodule
