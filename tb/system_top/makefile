# Default simulator
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
COMPILE_ARGS += -g2012

# Source files
VERILOG_SOURCES += $(PWD)/../../src/system_top.sv
VERILOG_SOURCES += $(PWD)/../../src/uart_programming/programmer.sv
VERILOG_SOURCES += $(PWD)/../../src/uart_programming/uart_rx.sv
VERILOG_SOURCES += $(PWD)/../../src/generic/fwft_fifo.sv
VERILOG_SOURCES += $(PWD)/../../src/fir/fir_top.sv
VERILOG_SOURCES += $(PWD)/../../src/fir/fir_control.sv
VERILOG_SOURCES += $(PWD)/../../src/fir/delay_line/delay_line.sv
VERILOG_SOURCES += $(PWD)/../../src/fir/mac/mac.sv
VERILOG_SOURCES += $(PWD)/../../src/generic/regfile.sv
VERILOG_SOURCES += $(PWD)/../../src/spi-axi/spi_axis_top.sv
VERILOG_SOURCES += $(PWD)/../../src/spi-axi/spi_slave.sv

TOPLEVEL = system_top
MODULE = tb_system_top
WAVES = 1

include $(shell cocotb-config --makefiles)/Makefile.sim
