import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

async def send_uart_byte(dut, data, clks_per_bit):
    # Send Start Bit
    dut.rx_line_i.value = 0
    await Timer(clks_per_bit * 20, unit="ns")

    # Send 8 Data Bits (LSB first)
    for i in range(8):
        bit = (data >> i) & 1
        dut.rx_line_i.value = bit
        await Timer(clks_per_bit * 20, unit="ns")

    # Send Stop Bit
    dut.rx_line_i.value = 1
    await Timer(clks_per_bit * 20, unit="ns")

@cocotb.test()
async def test_uart_rx(dut):
    # Initialize clock (Assuming 50 MHz -> 20 ns period)
    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())

    # Calculate clocks per bit from module parameters
    clk_freq = int(dut.CLK_FREQ.value)
    baud_rate = int(dut.BAUD_RATE.value)
    clks_per_bit = clk_freq // baud_rate

    # Initial state and Reset (active-low)
    dut.arst_n.value = 0
    dut.rx_line_i.value = 1
    
    await Timer(100, unit="ns")
    dut.arst_n.value = 1  # Release reset
    await Timer(100, unit="ns")

    test_data = [0x5A, 0xC3, 0xFF]
    received_data = []

    # Monitor Coroutine to capture received data
    async def monitor():
        while True:
            await RisingEdge(dut.data_valid_o)
            rx_byte = int(dut.data_o.value)
            received_data.append(rx_byte)
            dut._log.info(f"Received byte: 0x{rx_byte:02x}")

    cocotb.start_soon(monitor())

    # Send test data
    for byte in test_data:
        dut._log.info(f"Transmitting byte: 0x{byte:02x}")
        await send_uart_byte(dut, byte, clks_per_bit)
        await Timer(2000, unit="ns")  # Idle time between bytes

    # Verify received data
    assert len(received_data) == len(test_data), "ERROR: Received data length mismatch!"
    
    for i in range(len(test_data)):
        assert received_data[i] == test_data[i], f"ERROR: Mismatch! Sent 0x{test_data[i]:02x}, but received 0x{received_data[i]:02x}"

    dut._log.info("UART RX tests completed successfully.")