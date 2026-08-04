import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import random

class DelayLineGoldenModel:
    """Python Delay Line Golden Model for 32-tap FIR architecture"""
    def __init__(self):
        self.sipo_top = [0]*16  #Taps 1-16
        self.sipo_bot = [0]*16  #Taps 17-32

    def shift(self, data_in, mode_odd):
        bot_in = self.sipo_top[-1]
        self.sipo_bot = [bot_in] + self.sipo_bot[:-1]
        self.sipo_top = [data_in] + self.sipo_top[:-1]

    def get_expected_out(self, data_in, sel, mode_config):
        is_asym    = (mode_config & 0x4) == 0
        is_antisym = (mode_config & 0x6) == 0x6
        is_odd     = (mode_config & 0x5) == 0x5

        mux_top = self.sipo_top[15 - sel]
        
        if is_asym:
            mux_bot = 0
        elif is_odd:
            if sel == 0:
                mux_bot = 0
            else:
                mux_bot = self.sipo_bot[sel - 1]
        else:
            mux_bot = self.sipo_bot[sel]
            
        def to_signed16(val):
            return val - 0x10000 if (val & 0x8000) else val

        top_signed = to_signed16(mux_top)
        bot_signed = to_signed16(mux_bot)
        
        if is_antisym:
            adder_out = top_signed - bot_signed
        else:
            adder_out = top_signed + bot_signed

        # Masking disesuaikan untuk 17-bit (0x1FFFF)
        adder_out &= 0x1FFFF

        # Sign extension logic disesuaikan untuk 17-bit
        if adder_out & (1 << 16):
            adder_out -= (1 << 17)

        return adder_out


async def run_directed_test(dut, mode_config, test_name):
    model = DelayLineGoldenModel()

    with open("test_log_delay_line.txt", "a") as f:
        # Header test
        f.write("\n\n")
        f.write("=" * 60 + "\n")
        f.write(f"Start Testing Scenario: {test_name}\n")
        f.write("=" * 60 + "\n\n")

        # Reset DUT (Penyesuaian nama port input)
        dut.arst_n.value = 0
        dut.shift_en_i.value = 0
        dut.mode_i.value = mode_config
        dut.sample_i.value = 0
        dut.sel_i.value = 0

        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)
        dut.arst_n.value = 1
        await RisingEdge(dut.clk)

        is_odd_mode = (mode_config & 1) == 1

        # Load 32 data
        f.write("Shifting all 32 sample data into SIPO\n")

        for _ in range(32):
            val = random.randint(1, 100)

            dut.sample_i.value = val
            dut.shift_en_i.value = 1

            await RisingEdge(dut.clk)
            model.shift(val, is_odd_mode)

        dut.shift_en_i.value = 0
        await RisingEdge(dut.clk)

        # Print isi delay line
        f.write("\nInput Signal (Taps 1 to 32):\n")

        all_taps = model.sipo_top + model.sipo_bot

        for idx, tap_val in enumerate(all_taps, start=1):
            f.write(f"  Tap {idx:2d}: {tap_val}\n")

        # Test selector
        test_data = random.randint(1, 100)
        dut.sample_i.value = test_data

        f.write(f"\nTesting Selector ({test_name})\n")
        f.write("-" * 60 + "\n")

        for sel in range(16):
            dut.sel_i.value = sel
            await Timer(1, units="ns")

            # Penyesuaian nama port output
            actual_val = dut.sample_o.value.signed_integer
            expected_val = model.get_expected_out(test_data, sel, mode_config)

            f.write(
                f"sel {sel:2d}: Result = {actual_val:4d}, Expected = {expected_val:4d}\n"
            )

            assert actual_val == expected_val, (
                f"Fail at {test_name} [sel={sel}] -> "
                f"Expected: {expected_val}, Got: {actual_val}"
            )

        f.write("\n")
        f.write(f">>> {test_name} PASSED THE TEST\n")

@cocotb.test()
async def test_symmetric_even(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start()) 
    await run_directed_test(dut, mode_config=0b100, test_name="Symmetric Even")

@cocotb.test()
async def test_symmetric_odd(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await run_directed_test(dut, mode_config=0b101, test_name="Symmetric Odd")

@cocotb.test()
async def test_antisymmetric_even(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await run_directed_test(dut, mode_config=0b110, test_name="Anti-Symmetric Even")

@cocotb.test()
async def test_antisymmetric_odd(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await run_directed_test(dut, mode_config=0b111, test_name="Anti-Symmetric Odd")

@cocotb.test()
async def test_asymmetric(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await run_directed_test(dut, mode_config=0b000, test_name="Asymmetric")