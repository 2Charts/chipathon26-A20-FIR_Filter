import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

async def send_uart_byte(dut, data, clks_per_bit):
    dut.rx_serial.value = 0
    await Timer(clks_per_bit * 20, unit="ns")

    for i in range(8):
        bit = (data >> i) & 1
        dut.rx_serial.value = bit
        await Timer(clks_per_bit * 20, unit="ns")

    dut.rx_serial.value = 1
    await Timer(clks_per_bit * 20, unit="ns")

@cocotb.test()
async def test_uart_rx(dut):
    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst.value = 1
    dut.rx_serial.value = 1
    clks_per_bit = int(dut.CLKS_PER_BIT.value)
    
    await Timer(100, unit="ns")
    dut.rst.value = 0
    await Timer(100, unit="ns")

    test_data = [0x5A, 0xC3, 0xFF]
    received_data = []

    async def monitor():
        while True:
            await RisingEdge(dut.prog_valid)
            rx_byte = int(dut.prog_data.value)
            received_data.append(rx_byte)
            dut._log.info(f"-> [SUCCESS] UART RX received data: 0x{rx_byte:02x}")

    cocotb.start_soon(monitor())

    for byte in test_data:
        dut._log.info(f"Sending Byte: 0x{byte:02x}")
        await send_uart_byte(dut, byte, clks_per_bit)
        await Timer(2000, unit="ns")

    assert len(received_data) == len(test_data), "ERROR: Received data length mismatch!"
    
    for i in range(len(test_data)):
        assert received_data[i] == test_data[i], f"ERROR: Mismatch! Sent 0x{test_data[i]:02x}, but received 0x{received_data[i]:02x}"

    dut._log.info("Awesome! All UART RX tests passed successfully (PASS).")