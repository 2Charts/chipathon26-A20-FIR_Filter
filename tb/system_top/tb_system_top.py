import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ReadOnly
import sys
import os
import random

sys.path.append(os.path.abspath("../"))
import golden_model

# Simulation parameters
CLK_FREQ = 16_000_000
BAUD_RATE = 115200
BAUD_PERIOD_NS = int(1e9 / BAUD_RATE)
SPI_PERIOD_NS = 1000 # 1 MHz SPI Clock

async def reset_dut(dut):
    """Assert reset and initialize interfaces to idle states."""
    dut.rst_n.value = 0
    dut.uart_rx.value = 1
    dut.sck.value = 0
    dut.cs_n.value = 1
    dut.mosi.value = 0
    await Timer(100, unit="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

async def uart_send_byte(dut, byte_val):
    """Bit-bang a single UART byte (8N1) at the configured baud rate."""
    # Start bit
    dut.uart_rx.value = 0
    await Timer(BAUD_PERIOD_NS, unit="ns")
    
    # Data bits (LSB first)
    for i in range(8):
        dut.uart_rx.value = (byte_val >> i) & 1
        await Timer(BAUD_PERIOD_NS, unit="ns")
        
    # Stop bit
    dut.uart_rx.value = 1
    await Timer(BAUD_PERIOD_NS, unit="ns")
    # Small gap between bytes
    await Timer(BAUD_PERIOD_NS // 2, unit="ns")

async def load_coefficients_uart(dut, coeffs):
    """Send 16 coefficients via UART."""
    for i, c in enumerate(coeffs):
        # Header: MSB [0 X X X A A A A] LSB
        header = i & 0x0F
        await uart_send_byte(dut, header)
        
        # 16-bit Q15 Coefficient (Little Endian)
        c_uint16 = c & 0xFFFF
        await uart_send_byte(dut, c_uint16 & 0xFF)         # LSB
        await uart_send_byte(dut, (c_uint16 >> 8) & 0xFF)  # MSB

async def configure_mode_uart(dut, mode):
    """Configure filter mode via UART."""
    # Header: MSB [1 C C C R R R R] LSB
    header = 0x80 | ((mode & 0x07) << 4)
    await uart_send_byte(dut, header)
    # Wait for system_top to process UART packet
    await Timer(5, unit="us")

async def spi_transact(dut, data_in):
    """Perform a 16-bit SPI Mode 0 transaction, return the received data."""
    # SPI Mode 0: CPOL=0 (Idle low), CPHA=0 (Sample on leading/rising edge, shift on trailing/falling)
    dut.cs_n.value = 0
    dut.sck.value = 0
    data_out = 0
    
    # Setup delay after CS asserted
    await Timer(SPI_PERIOD_NS // 4, unit="ns")
    
    for i in range(15, -1, -1):
        # Master drives MOSI (MSB first)
        dut.mosi.value = (data_in >> i) & 1
        await Timer(SPI_PERIOD_NS // 4, unit="ns")
        
        # Rising edge
        dut.sck.value = 1
        await ReadOnly()
        bit_in = int(dut.miso.value) if dut.miso.value.is_resolvable else 0
        data_out = (data_out << 1) | bit_in
        
        await Timer(SPI_PERIOD_NS // 2, unit="ns")
        
        # Falling edge
        dut.sck.value = 0
        await Timer(SPI_PERIOD_NS // 4, unit="ns")
        
    dut.cs_n.value = 1
    await Timer(SPI_PERIOD_NS, unit="ns")
    
    # Sign-extend 16-bit to signed integer
    if data_out & 0x8000:
        data_out -= 0x10000
        
    return data_out

@cocotb.test()
async def test_system_top(dut):
    """System Top Level Test via UART and SPI."""
    cocotb.start_soon(Clock(dut.clk, int(1e9 / CLK_FREQ), unit="ns").start())

    modes = [0, 4, 5, 6, 7]
    mode_names = {0: "Asym", 4: "Sym Even", 5: "Sym Odd", 6: "Anti Even", 7: "Anti Odd"}
    NUM_SAMPLES = 50
    
    log_file_path = "system_top_log.txt"
    with open(log_file_path, "w") as f:
        f.write("=== Verification Log ===\n\n")

    for mode in modes:
        dut._log.info(f"--- Testing Mode: {mode_names[mode]} ---")
        
        # 1. GENERATE VECTORS
        coeffs = [random.randint(-16384, 16383) for _ in range(16)]
        samples = [random.randint(-32768, 32767) for _ in range(NUM_SAMPLES)]
        
        # 2. EXPECTED MODELS
        hw_expected = golden_model.get_hardware_accurate_output(samples, coeffs, mode)
        fl_expected = golden_model.get_floating_point_output(samples, coeffs, mode)
        
        # 3. CONFIGURE HARDWARE
        await reset_dut(dut)
        dut._log.info("Loading coefficients over UART...")
        await load_coefficients_uart(dut, coeffs)
        dut._log.info("Configuring mode over UART...")
        await configure_mode_uart(dut, mode)
        
        # 4. STREAM DATA VIA SPI
        dut._log.info("Streaming data over SPI...")
        rtl_results = []
        
        # Output is returned in the next transaction. 
        # N+1 Transactions for N samples
        for i in range(NUM_SAMPLES + 1):
            s_val = samples[i] & 0xFFFF if i < NUM_SAMPLES else 0x0000
            m_val = await spi_transact(dut, s_val)
            
            # First transaction returns garbage
            if i > 0:
                rtl_results.append(m_val)
                
        # 5. LOGGING AND ASSERTIONS
        hw_mismatches = 0
        
        with open(log_file_path, "a") as f:
            f.write(f"--- FILTER MODE: {mode_names[mode]} (Code: {mode}) ---\n")
            f.write("Coefficients:\n")
            for i, c in enumerate(coeffs):
                c_float = c / 32768.0
                f.write(f"  Tap {i:2}: Q15 = {c:6d}, Float = {c_float:+.6f}\n")
            f.write("\n")
            
            header_str = (f"| {'Idx':^4} | {'Input':^7} | {'RTL Out':^8} | "
                          f"{'HW Exp':^8} | {'Math Exp':^9} | "
                          f"{'HW Err':^6} | {'Math Err':^8} | {'Status':^6} |")
            f.write("-" * len(header_str) + "\n")
            f.write(header_str + "\n")
            f.write("-" * len(header_str) + "\n")
            
            for i in range(NUM_SAMPLES):
                inp = samples[i]
                rtl = rtl_results[i]
                hw  = hw_expected[i]
                fl  = fl_expected[i]
                
                hw_err = abs(rtl - hw)
                fl_err = abs(rtl - fl)
                
                status = "PASS" if hw_err == 0 else "FAIL"
                if hw_err != 0:
                    hw_mismatches += 1
                
                row_str = (f"| {i:4d} | {inp:7d} | {rtl:8d} | "
                           f"{hw:8d} | {fl:9d} | "
                           f"{hw_err:6d} | {fl_err:8d} | {status:6} |")
                f.write(row_str + "\n")
            
            f.write("-" * len(header_str) + "\n\n")

        assert hw_mismatches == 0, f"Hardware mismatch detected in mode: {mode_names[mode]}!"
        dut._log.info(f"Mode {mode_names[mode]} Passed. Log appended to {log_file_path}.")

    dut._log.info(f"All modes verified successfully! Full log available at: {log_file_path}")