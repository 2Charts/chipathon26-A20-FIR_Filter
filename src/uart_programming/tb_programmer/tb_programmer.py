import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, FallingEdge

# =========================================================================
# TEST CONSTANTS 
# =========================================================================
CLK_FREQ_HZ = 50_000_000  # 50 MHz
BAUD_RATE   = 115200      # 115200 bps

# =========================================================================
# HELPER FUNCTIONS
# =========================================================================
async def uart_send_byte(dut, data_byte, baud_rate=BAUD_RATE):
    bit_time_ns = int(1e9 / baud_rate)
    
    dut.rx_line_i.value = 0
    await Timer(bit_time_ns, unit="ns")
    
    for i in range(8):
        bit_val = (data_byte >> i) & 1
        dut.rx_line_i.value = bit_val
        await Timer(bit_time_ns, unit="ns")
        
    dut.rx_line_i.value = 1
    await Timer(bit_time_ns, unit="ns")

async def monitor_config(dut):
    for _ in range(25000):
        await FallingEdge(dut.clk)
        if dut.config_wr_en_o.value == 1:
            return dut.config_data_o.value
    raise TimeoutError("Sinyal config_wr_en_o tidak pernah menyala!")

async def monitor_coeff(dut):
    for _ in range(50000): 
        await FallingEdge(dut.clk)
        if dut.coeff_wr_en_o.value == 1:
            return dut.coeff_addr_o.value, dut.coeff_data_o.value
    raise TimeoutError("Sinyal coeff_wr_en_o tidak pernah menyala!")

# =========================================================================
# MAIN TEST SCENARIOS (WITH RANDOMIZED INPUTS)
# =========================================================================
@cocotb.test()
async def test_programmer_flow(dut):
    """Testbench to validate the UART to FIR Programmer FSM using Randomized Inputs"""
    
    clock_period_ns = int(1e9 / CLK_FREQ_HZ)
    clock = Clock(dut.clk, clock_period_ns, unit="ns")
    cocotb.start_soon(clock.start())
    
    dut._log.info("Performing System Reset...")
    dut.rx_line_i.value = 1 
    dut.arst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.arst_n.value = 1
    await ClockCycles(dut.clk, 5)
    
    # =====================================================================
    # SCENARIO 1: Random Configuration
    # =====================================================================
    # Membangkitkan data config random (nilai 0-15 agar masuk ke 4-bit config)
    rand_config_val = random.randint(0, 0x0F)
    rand_config_byte = 0x80 | rand_config_val  # Bit ke-7 diset 1 sebagai header config
    
    dut._log.info("=== SCENARIO 1: Configuration Transmission (Randomized) ===")
    dut._log.info(f"  [INPUT]   UART RX Stream : {hex(rand_config_byte)} (Random Config Value: {hex(rand_config_val)})")
    dut._log.info("  [PROCESS] FSM evaluates byte, decodes configuration data, and asserts write enable.")
    
    cocotb.start_soon(uart_send_byte(dut, rand_config_byte))
    config_data = await monitor_config(dut)
    assert config_data == rand_config_val, f"Error: Wrong config data! Expected {hex(rand_config_val)}, read {hex(config_data)}"
    
    dut._log.info(f"  [OUTPUT]  config_data_o  : {hex(config_data)}")
    dut._log.info(f"  [OUTPUT]  config_wr_en_o : 1")
    dut._log.info("  [STATUS]  Scenario 1 PASSED!\n")
    await ClockCycles(dut.clk, 100)

    # =====================================================================
    # SCENARIO 2: Random Coefficients
    # =====================================================================
    # Membangkitkan alamat random (0x00 sampai 0x1F) dan data 16-bit random
    rand_addr = random.randint(0, 0x0F)
    rand_data_16 = random.randint(0, 0xFFFF)
    rand_low_byte = rand_data_16 & 0xFF
    rand_high_byte = (rand_data_16 >> 8) & 0xFF
    
    dut._log.info("=== SCENARIO 2: Coefficient Transmission (Randomized) ===")
    dut._log.info(f"  [INPUT]   UART RX Stream : Address = {hex(rand_addr)}, Low Byte = {hex(rand_low_byte)}, High Byte = {hex(rand_high_byte)}")
    dut._log.info("  [PROCESS] FSM captures address in ST_IDLE, receives low byte, and assembles 16-bit data with high byte.")
    
    async def send_coef():
        await uart_send_byte(dut, rand_addr) 
        await uart_send_byte(dut, rand_low_byte) 
        await uart_send_byte(dut, rand_high_byte) 
        
    cocotb.start_soon(send_coef())
    addr, data = await monitor_coeff(dut)
    assert addr == rand_addr, f"Error: Wrong address! Expected {hex(rand_addr)}, read {hex(addr)}"
    assert data == rand_data_16, f"Error: Wrong coefficient data! Expected {hex(rand_data_16)}, read {hex(data)}"
    
    dut._log.info(f"  [OUTPUT]  coeff_addr_o   : {hex(addr)}")
    dut._log.info(f"  [OUTPUT]  coeff_data_o   : {hex(data)}")
    dut._log.info(f"  [OUTPUT]  coeff_wr_en_o  : 1")
    dut._log.info("  [STATUS]  Scenario 2 PASSED!\n")
    await ClockCycles(dut.clk, 100)
    
    # =====================================================================
    # SCENARIO 3: Dynamic Timeout Test with Random Recovery
    # =====================================================================
    rand_recovery_addr = random.randint(0, 0x0F)
    rand_recovery_data = random.randint(0, 0xFFFF)
    rec_low = rand_recovery_data & 0xFF
    rec_high = (rand_recovery_data >> 8) & 0xFF
    
    dut._log.info("=== SCENARIO 3: Dynamic Timeout Test ===")
    dut._log.info("  [INPUT]   UART RX Stream : Fake Header (0x09) followed by stalling / idle line")
    dut._log.info("  [PROCESS] FSM hangs, timeout counter triggers a reset back to ST_IDLE, followed by new random transaction.")
    
    await uart_send_byte(dut, 0x09) 
    await ClockCycles(dut.clk, 25000)
    
    async def send_new():
        await uart_send_byte(dut, rand_recovery_addr) 
        await uart_send_byte(dut, rec_low) 
        await uart_send_byte(dut, rec_high) 
        
    cocotb.start_soon(send_new())
    addr, data = await monitor_coeff(dut)
    assert addr == rand_recovery_addr, f"Timeout Error: FSM stuck! Expected {hex(rand_recovery_addr)}, read {hex(addr)}"
    assert data == rand_recovery_data, f"Timeout Error: Wrong assembled data! Expected {hex(rand_recovery_data)}, read {hex(data)}"
    
    dut._log.info(f"  [OUTPUT]  coeff_addr_o   : {hex(addr)}")
    dut._log.info(f"  [OUTPUT]  coeff_data_o   : {hex(data)}")
    dut._log.info(f"  [OUTPUT]  coeff_wr_en_o  : 1")
    dut._log.info("  [STATUS]  Scenario 3 PASSED! FSM successfully recovered via timeout.\n")
    
    dut._log.info("=== ALL TESTS COMPLETED SUCCESSFULLY ===")