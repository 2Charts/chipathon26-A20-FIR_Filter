import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ReadOnly
import sys
import os
import random

# Add golden_model.py to path
sys.path.append(os.path.abspath("../"))
import golden_model

async def reset_dut(dut):
    dut.arst_n.value = 0
    await Timer(20, units="ns")
    dut.arst_n.value = 1
    await RisingEdge(dut.clk)

async def load_coefficients(dut, coeffs):
    for i, c in enumerate(coeffs):
        dut.coeff_addr_i.value = i
        # Convert to 16-bit logic properly
        dut.coeff_data_i.value = c & 0xFFFF
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
        dut.s_axis_tdata_i.value = d & 0xFFFF
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
                dut._log.error(f"X or Z in m_axis_tdata_o")
                results.append(0)
    await RisingEdge(dut.clk)
    return results

@cocotb.test()
async def test_fir_dual_model(dut):
    """Test FIR with Source, Dual Golden Models, and Checker"""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Initialize
    dut.s_axis_tvalid_i.value = 0
    dut.s_axis_tdata_i.value = 0
    dut.m_axis_tready_i.value = 1
    dut.config_wr_en_i.value = 0
    dut.coeff_wr_en_i.value = 0
    
    await reset_dut(dut)
    
    # Modes to test: Asym (0), Sym Even (4), Sym Odd (5), Anti Even (6), Anti Odd (7)
    modes = [0, 4, 5, 6, 7]
    mode_names = {0: "Asym", 4: "Sym Even", 5: "Sym Odd", 6: "Anti Even", 7: "Anti Odd"}
    
    NUM_SAMPLES = 200
    
    for mode in modes:
        dut._log.info(f"--- Testing Mode: {mode_names[mode]} ---")
        
        # 1. SOURCE: Generate Random Coefficients and Data
        # Using smaller random numbers to avoid massive overflow before >>15, though it handles it.
        # Random coeffs between -16384 and 16383 (Q15 range)
        coeffs = [random.randint(-16384, 16383) for _ in range(16)]
        
        # Random samples between -32768 and 32767
        samples = [random.randint(-32768, 32767) for _ in range(NUM_SAMPLES)]
        
        # 2. REFERENCE MODELS
        hw_expected = golden_model.get_hardware_accurate_output(samples, coeffs, mode)
        fl_expected = golden_model.get_floating_point_output(samples, coeffs, mode)
        
        # 3. RTL EXECUTION
        await reset_dut(dut)
        await load_coefficients(dut, coeffs)
        await configure_mode(dut, mode)
        
        # Stream data in and out
        recv_task = cocotb.start_soon(receive_axis_data(dut, len(samples)))
        await send_axis_data(dut, samples)
        rtl_results = await recv_task
        
        # 4. CHECKER
        hw_mismatches = 0
        fl_mismatches = 0
        
        for i in range(NUM_SAMPLES):
            # Hardware accurate checker (Tolerance = 0)
            if rtl_results[i] != hw_expected[i]:
                hw_mismatches += 1
                if hw_mismatches <= 5: # Limit logging
                    dut._log.error(f"HW Mismatch at {i}: RTL={rtl_results[i]}, HW_MODEL={hw_expected[i]}")
                    
            # Floating point checker (Tolerance = +/- 1 LSB)
            fl_err = abs(rtl_results[i] - fl_expected[i])
            if fl_err > 1:
                fl_mismatches += 1
                if fl_mismatches <= 5: # Limit logging
                    dut._log.error(f"FL Mismatch at {i}: RTL={rtl_results[i]}, FL_MODEL={fl_expected[i]}, ERR={fl_err}")
                    
        if hw_mismatches == 0:
            dut._log.info("HW Exact Checker: PASSED (0 Error)")
        else:
            dut._log.error(f"HW Exact Checker: FAILED with {hw_mismatches} mismatches")
            
        if fl_mismatches == 0:
            dut._log.info("Floating Point Checker: PASSED (Error <= 1 LSB)")
        else:
            dut._log.error(f"Floating Point Checker: FAILED with {fl_mismatches} mismatches")
            
        # We expect hardware to exactly match HW model
        assert hw_mismatches == 0, f"Hardware exact model failed for {mode_names[mode]}"
        
        # We also assert floating point matches to prove it mathematically acts like a filter.
        # Note: If RTL has a bug, this assertion will catch it!
        assert fl_mismatches == 0, f"Floating point math failed for {mode_names[mode]}! This indicates an RTL bug!"
        
    dut._log.info("ALL TESTS COMPLETED!")
