import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

class MACLogger:
    def __init__(self, dut, name):
        self.dut = dut
        self.name = name
        self.passed = 0
        self.failed = 0
        self.dut._log.info(f"\n{'='*80}\nStart Testing Scenario: {name}\n{'='*80}")
        self.dut._log.info(f"{'Test Case':<12} | {'y (Q1.15)':<12} | {'Expected':<12} | {'Status'}")
        self.dut._log.info("-" * 80)

    def log(self, test_case, y, expected):
        status = "PASS" if y == expected else "FAIL"
        if status == "PASS":
            self.passed += 1
        else:
            self.failed += 1
        self.dut._log.info(f"{test_case:<12} | {y:<12} | {expected:<12} | {status}")

    def report(self):
        self.dut._log.info("-" * 80)
        self.dut._log.info(f">>> {self.name} : {self.passed} PASSED, {self.failed} FAILED\n")
        assert self.failed == 0, f"Test {self.name} failed with {self.failed} errors"


async def feed_mac(dut, x_vals, c_vals, clear_first=True):
    """Feeds sequence into MAC and flushes pipelined outputs (2-cycle latency)."""
    n = len(x_vals)
    dut.enable_i.value = 1
    
    for i in range(n + 2):
        dut.clear_i.value = 1 if (i == 0 and clear_first) else 0
        
        if i < n:
            dut.sample_i.value = x_vals[i]
            dut.coeff_i.value = c_vals[i]
        else:
            dut.sample_i.value = 0
            dut.coeff_i.value = 0
            
        await RisingEdge(dut.clk)
        
    dut.enable_i.value = 0
    await RisingEdge(dut.clk)


@cocotb.test()
async def mac_pipeline_test(dut):
    """Testbench for Q15 MAC Engine"""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Initialize ports mapping to the new module names
    dut.arst_n.value = 1
    dut.enable_i.value = 0
    dut.clear_i.value = 0
    dut.sample_i.value = 0
    dut.coeff_i.value = 0

    # Reset sequence
    dut.arst_n.value = 0
    await Timer(20, units="ns")
    dut.arst_n.value = 1
    await RisingEdge(dut.clk)

    # Define all test scenarios compactly
    test_scenarios = [
        {
            "name": "Basic MAC Operations",
            "tests": [
                ("Basic", [16384, 16384], [16384, 8192], 12288)
            ]
        },
        {
            "name": "17-bit Input Handling",
            "tests": [
                ("17-bit Pos", [49152], [16384], 24576),
                ("17-bit Neg", [-65536], [8192], -16384)
            ]
        },
        {
            "name": "Rounding Verification",
            "tests": [
                ("Round Up", [128], [128], 1),
                ("Round Down", [1], [16383], 0),
                ("Neg Rnd Up", [-128], [128], 0),
                ("Neg Rnd Dn", [-1], [16385], -1)
            ]
        },
        {
            "name": "Saturation Verification",
            "tests": [
                ("Pos Over", [65535]*3, [32767]*3, 32767),
                ("Neg Over", [-65536]*3, [32767]*3, -32768)
            ]
        }
    ]

    for scenario in test_scenarios:
        logger = MACLogger(dut, scenario["name"])
        for test_name, x_vals, c_vals, expected in scenario["tests"]:
            await feed_mac(dut, x_vals, c_vals, clear_first=True)
            y_val = dut.result_o.value.to_signed() # to_signed() prevents cocotb deprecation warnings
            logger.log(test_name, y_val, expected)
        logger.report()

    dut._log.info("=" * 80)
    dut._log.info("ALL MAC SCENARIOS PASSED")
    dut._log.info("=" * 80 + "\n")