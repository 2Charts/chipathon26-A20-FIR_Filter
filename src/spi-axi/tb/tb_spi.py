import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles
import random

# -----------------------------------------------------------------------------
# AXI Stream Helper Coroutines
# -----------------------------------------------------------------------------

async def axis_send(dut, data_list):
    """Drives data into the AXI Stream Slave interface."""
    for data in data_list:
        dut.s_axis_tdata_i.value = data
        dut.s_axis_tvalid_i.value = 1
        
        await RisingEdge(dut.clk)
        # Wait until DUT accepts the data
        while dut.s_axis_tready_o.value == 0:
            await RisingEdge(dut.clk)
            
    dut.s_axis_tvalid_i.value = 0


async def axis_recv(dut, count):
    """Reads a specified number of transactions from the AXI Stream Master interface."""
    recv_data = []
    dut.m_axis_tready_i.value = 1
    
    while len(recv_data) < count:
        await RisingEdge(dut.clk)
        if dut.m_axis_tvalid_o.value == 1 and dut.m_axis_tready_i.value == 1:
            try:
                val = int(dut.m_axis_tdata_o.value)
            except ValueError:
                val = 0
            recv_data.append(val)
            
    dut.m_axis_tready_i.value = 0
    return recv_data

# -----------------------------------------------------------------------------
# SPI Master Helper Coroutine
# -----------------------------------------------------------------------------

async def spi_transaction(dut, mosi_data, sck_period_ns=100):
    """
    Simulates an SPI Master transaction.
    Mode 0: CPOL=0, CPHA=0 (Sample on rising edge, shift on falling edge).
    MSB first, 16 bits.
    """
    half_period = sck_period_ns / 2.0
    
    # Assert CS (Active Low)
    dut.cs_n_i.value = 0
    await Timer(sck_period_ns, unit="ns")
    
    miso_data = 0
    for i in range(16):
        # MSB first
        bit = (mosi_data >> (15 - i)) & 1
        dut.mosi_i.value = bit
        
        # Setup time before rising edge
        await Timer(half_period, unit="ns")
        
        # Leading edge (Rising) - Sample MISO
        dut.sck_i.value = 1
        try:
            miso_bit = int(dut.miso_o.value)
        except ValueError:
            miso_bit = 0
        miso_data = (miso_data << 1) | miso_bit
        
        # Hold time before falling edge
        await Timer(half_period, unit="ns")
        
        # Trailing edge (Falling) - Shift occurs
        dut.sck_i.value = 0
    
    # Wait a bit before de-asserting CS
    await Timer(half_period, unit="ns")
    dut.cs_n_i.value = 1
    
    # Delay between transactions
    await Timer(sck_period_ns * 2, unit="ns")
    
    return miso_data

# -----------------------------------------------------------------------------
# Reset Sequence
# -----------------------------------------------------------------------------

async def reset_dut(dut):
    """Applies initial values and resets the DUT."""
    # Initialize inputs
    dut.s_axis_tdata_i.value = 0
    dut.s_axis_tvalid_i.value = 0
    dut.m_axis_tready_i.value = 0
    
    dut.sck_i.value = 0
    dut.cs_n_i.value = 1
    dut.mosi_i.value = 0
    
    # Apply reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)

# -----------------------------------------------------------------------------
# Main Test Cases
# -----------------------------------------------------------------------------

@cocotb.test()
async def test_full_duplex_traffic(dut):
    """Test full duplex data transfer over SPI and AXI Stream."""
    
    # Start 100MHz system clock (10ns period)
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())
    
    await reset_dut(dut)
    
    # Define test parameters
    NUM_TRANSACTIONS = 5
    
    # Generate random test data
    axis_tx_data = [random.randint(0, 0xFFFF) for _ in range(NUM_TRANSACTIONS)]
    spi_tx_data = [random.randint(0, 0xFFFF) for _ in range(NUM_TRANSACTIONS)]
    
    dut._log.info(f"AXIS TX Data: {[hex(x) for x in axis_tx_data]}")
    dut._log.info(f"SPI  TX Data: {[hex(x) for x in spi_tx_data]}")
    
    # 1. Start concurrent AXI Stream receiver
    axis_recv_thread = cocotb.start_soon(axis_recv(dut, NUM_TRANSACTIONS))
    
    # 2. Feed data into AXI Stream Slave (This data should go out via MISO)
    await axis_send(dut, axis_tx_data)
    
    # Give the DUT some clock cycles to process the AXI data into its internal FIFO
    await ClockCycles(dut.clk, 20)
    
    # 3. Perform SPI transactions (Receiving the AXIS data on MISO, Sending SPI data on MOSI)
    spi_rx_data = []
    for mosi_val in spi_tx_data:
        # sck_period = 100ns (10MHz) -> 10x slower than 100MHz sys clk
        miso_val = await spi_transaction(dut, mosi_val, sck_period_ns=100)
        spi_rx_data.append(miso_val)
        
    dut._log.info(f"SPI  RX Data (from MISO): {[hex(x) for x in spi_rx_data]}")
    
    # 4. Wait for the AXI Stream receiver to collect the data sent via SPI
    axis_rx_data = await axis_recv_thread
    dut._log.info(f"AXIS RX Data (from MOSI): {[hex(x) for x in axis_rx_data]}")
    
    # 5. Verify Results and Log to File
    
    # Check if the data matches
    miso_passed = (spi_rx_data == axis_tx_data)
    mosi_passed = (axis_rx_data == spi_tx_data)
    test_passed = miso_passed and mosi_passed
    
    # Write the summary to a log file
    with open("sim_log/simulation_results.log", "w") as log_file:
        log_file.write("=== SPI-AXIS Simulation Results ===\n")
        
        log_file.write("\n--- MISO Path (AXI Stream -> SPI) ---\n")
        log_file.write(f"AXIS TX Data (Injected) : {[hex(x) for x in axis_tx_data]}\n")
        log_file.write(f"SPI RX Data  (Sampled)  : {[hex(x) for x in spi_rx_data]}\n")
        log_file.write(f"Path Status: {'PASSED' if miso_passed else 'FAILED'}\n")
        
        log_file.write("\n--- MOSI Path (SPI -> AXI Stream) ---\n")
        log_file.write(f"SPI TX Data  (Injected) : {[hex(x) for x in spi_tx_data]}\n")
        log_file.write(f"AXIS RX Data (Sampled)  : {[hex(x) for x in axis_rx_data]}\n")
        log_file.write(f"Path Status: {'PASSED' if mosi_passed else 'FAILED'}\n")
        
        log_file.write("\n===================================\n")
        if test_passed:
            log_file.write("OVERALL STATUS: PASSED\n")
        else:
            log_file.write("OVERALL STATUS: FAILED\n")

    # Raise the assertion errors
    assert miso_passed, "Data read via SPI MISO does not match data injected via AXI Stream."
    assert mosi_passed, "Data read via AXI Stream does not match data injected via SPI MOSI."
    
    dut._log.info("Test finished successfully. Results written to 'simulation_results.log'.")
