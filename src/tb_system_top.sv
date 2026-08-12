`timescale 1ns/1ps

module tb_system_top;

    logic clk;
    logic rst_n;
    
    logic sck;
    logic cs_n;
    logic mosi;
    logic miso;
    
    logic uart_rx;
    logic spi_start;
    logic miso_oe;
    
    // Power pins for Gate-Level Simulation
    supply1 VDD;
    supply0 VSS;
    
    // instantiate the top level wrapper
    system_top dut (.*);
    
    // just loop it back so we get something out
    assign mosi = miso;
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // helper task to send bytes over uart
    task send_uart_byte(input [7:0] byte_data);
        begin
            uart_rx = 0; // start bit
            #(434 * 10); 
            
            for (int i=0; i<8; i++) begin
                uart_rx = byte_data[i];
                #(434 * 10);
            end
            
            uart_rx = 1; // stop bit
            #(434 * 10);
        end
    endtask
    
    initial begin
        $dumpfile("waveform_sys.vcd");
        $dumpvars(0, tb_system_top);
        
`ifdef GL_SIM
        $sdf_annotate("final/sdf/nom_tt_025C_5v00/system_top__nom_tt_025C_5v00.sdf", dut);
`endif
        
        rst_n = 0;
        uart_rx = 1;
        spi_start = 0;
        
        // Initialize SPI inputs to prevent X propagation
        sck = 0;
        cs_n = 1;
        
        #100 rst_n = 1;
        @(posedge clk);
        
        // config filter for Asymmetric mode (011x)
        // LSB first: Data Low, Data High, Header
        send_uart_byte(8'h00);
        send_uart_byte(8'h00);
        send_uart_byte(8'b0000_0110); 
        
        // write all 16 coefficients to avoid uninitialized memory (X states)
        for (int i=0; i<16; i++) begin
            // write coef = i+1
            send_uart_byte((i+1) & 8'hFF); // Data Low
            send_uart_byte(8'h00);         // Data High
            
            // Header: Command 1xxx (bit 3=1), Addr = i (bits 7:4)
            send_uart_byte({i[3:0], 4'b1000}); 
        end
        
        // wait a bit for UART to finish
        #10000;
        
        // send 5 samples via SPI
        for (int i=0; i<5; i++) begin
            spi_start = 1;
            @(posedge clk);
            spi_start = 0;
            
            // wait for the SPI transaction (16 clocks * CLK_DIV) + FIR calc time (16 clocks)
            #5000; 
        end
        
        $display("System Top compiled and initialized fine!");
        
`ifndef GL_SIM
        // Let's dump all coeff_mem values (RTL ONLY)
        for (int i=0; i<16; i++) begin
            $display("coeff_mem[%0d] = %h", i, dut.config_inst.coeff_mem[i]);
        end
`endif
        
        $finish;
    end
    
    always @(negedge clk) begin
`ifndef GL_SIM
        if ($time > 2224000000 && $time < 2225000000) begin
            if (dut.controller_inst.state == 1) begin // CALC state
                $display("T=%0t: calc_cnt=%d, sel=%d, mac_x=%h, mac_c=%h, product=%h, acc=%h, y=%h", 
                         $time, 
                         dut.controller_inst.calc_cnt, 
                         dut.controller_inst.sel, 
                         dut.mac_inst.x, 
                         dut.mac_inst.c, 
                         dut.mac_inst.product,
                         dut.mac_inst.accumulator,
                         dut.mac_inst.y);
            end
        end
`endif
    end

endmodule
