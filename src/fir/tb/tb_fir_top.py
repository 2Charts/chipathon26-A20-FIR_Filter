import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ReadOnly

async def reset_dut(dut):
    dut.arst_n.value = 0
    await Timer(20, units="ns")
    dut.arst_n.value = 1
    await RisingEdge(dut.clk)

async def load_coefficients(dut, coeffs):
    for i, c in enumerate(coeffs):
        dut.coeff_addr_i.value = i
        dut.coeff_data_i.value = c
        dut.coeff_wr_en_i.value = 1
        await RisingEdge(dut.clk)
    dut.coeff_wr_en_i.value = 0
    await RisingEdge(dut.clk)

async def configure_mode(dut, mode):
    dut.config_data_i.value = (mode << 4)
    dut.config_wr_en_i.value = 1
    await RisingEdge(dut.clk)
    dut.config_wr_en_i.value = 0
    await RisingEdge(dut.clk)

async def send_axis_data(dut, data):
    for d in data:
        dut.s_axis_tdata_i.value = d
        dut.s_axis_tvalid_i.value = 1
        while True:
            await RisingEdge(dut.clk)
            if dut.s_axis_tready_o.value == 1:
                break
    dut.s_axis_tvalid_i.value = 0

async def receive_axis_data(dut, num_samples):
    results = []
    dut.m_axis_tready_i.value = 1
    while len(results) < num_samples:
        await RisingEdge(dut.clk)
        await ReadOnly()
        if dut.m_axis_tvalid_o.value == 1 and dut.m_axis_tready_i.value == 1:
            try:
                val = dut.m_axis_tdata_o.value.to_signed()
                results.append(val)
            except ValueError:
                dut._log.error(f"X or Z in m_axis_tdata_o: {dut.m_axis_tdata_o.value.binstr}")
                results.append(0)
    return results

@cocotb.test()
async def test_fir_impulse(dut):
    """Test FIR with an impulse response"""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Initialize
    dut.s_axis_tvalid_i.value = 0
    dut.s_axis_tdata_i.value = 0
    dut.m_axis_tready_i.value = 1
    
    dut.config_wr_en_i.value = 0
    dut.coeff_wr_en_i.value = 0
    
    # Tie unused signals to 0 if any
    
    await reset_dut(dut)
    
    # We will test an impulse response with decaying coefficients
    # Using Q15 formatting where 32768 is ~1.0
    # Let's use 16384 (0.5), 8192 (0.25), 4096 (0.125)...
    coeffs = [16384, 8192, 4096, 2048, 1024, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1, 0]
    await load_coefficients(dut, coeffs)
    await configure_mode(dut, 0) # 0 = asymmetric

    # Send an impulse
    input_data = [1000] + [0]*19
    
    recv_task = cocotb.start_soon(receive_axis_data(dut, len(input_data)))
    await send_axis_data(dut, input_data)
    
    results = await recv_task
    
    dut._log.info("Expected outputs are the input impulse scaled by the coefficients.")
    dut._log.info(f"Results: {results}")
    
    # Verification
    expected = []
    for c in coeffs:
        # MAC formula: (val * c + 0x4000) >> 15
        expected_val = (1000 * c + 0x4000) >> 15
        expected.append(expected_val)
    
    # The last 4 samples of input_data are just flushing out zeros
    expected += [0, 0, 0, 0]
    
    dut._log.info(f"Expected: {expected}")
    
    for i in range(len(expected)):
        assert results[i] == expected[i], f"Mismatch at index {i}: expected {expected[i]}, got {results[i]}"

    dut._log.info("FIR Impulse Test PASSED!")
