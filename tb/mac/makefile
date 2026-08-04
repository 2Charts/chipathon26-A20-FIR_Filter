# Default simulator
SIM ?= icarus

# Bahasa Toplevel
TOPLEVEL_LANG ?= verilog

# Konfigurasi agar Icarus membaca SystemVerilog
COMPILE_ARGS += -g2012

# Lokasi file RTL
VERILOG_SOURCES += $(PWD)/../../src/fir/mac/mac.sv

# Nama modul toplevel di SystemVerilog
TOPLEVEL = mac

# Nama file python testbench (tanpa .py)
MODULE = tb_mac

WAVES = 1

# Include cocotb makefile
include $(shell cocotb-config --makefiles)/Makefile.sim