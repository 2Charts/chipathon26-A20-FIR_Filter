# Makefile untuk Cocotb
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# File sumber RTL milikmu
VERILOG_SOURCES += $(PWD)/delay_line.sv

# Nama modul di dalam SystemVerilog
TOPLEVEL = delay_line

# Nama file Python testbench (tanpa ekstensi .py)
COCOTB_TEST_MODULES = tb_delay_line

include $(shell cocotb-config --makefiles)/Makefile.sim