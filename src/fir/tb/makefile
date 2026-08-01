# Default simulator
SIM ?= icarus

# Bahasa Toplevel
TOPLEVEL_LANG ?= verilog

# Konfigurasi agar Icarus membaca SystemVerilog
COMPILE_ARGS += -g2012

# Lokasi file RTL
VERILOG_SOURCES += ../fir_top.sv
VERILOG_SOURCES += ../fir_control.sv
VERILOG_SOURCES += ../delay_line/delay_line.sv
VERILOG_SOURCES += ../mac/mac.sv
VERILOG_SOURCES += ../../generic/regfile.sv

# Nama modul toplevel di SystemVerilog
TOPLEVEL = fir_top

# Nama file python testbench (tanpa .py)
MODULE = tb_fir_top

WAVES = 1

# Include cocotb makefile
include $(shell cocotb-config --makefiles)/Makefile.sim
