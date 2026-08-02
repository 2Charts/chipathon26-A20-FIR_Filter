# Default simulator
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
COMPILE_ARGS += -g2012

# Source files
VERILOG_SOURCES += $(PWD)/system_top.sv
VERILOG_SOURCES += $(PWD)/uart_programming/programmer.sv
VERILOG_SOURCES += $(PWD)/uart_programming/uart_rx.sv
VERILOG_SOURCES += $(PWD)/generic/fwft_fifo.sv
VERILOG_SOURCES += $(PWD)/fir/fir_top.sv
VERILOG_SOURCES += $(PWD)/fir/fir_control.sv
VERILOG_SOURCES += $(PWD)/fir/delay_line/delay_line.sv
VERILOG_SOURCES += $(PWD)/fir/mac/mac.sv
VERILOG_SOURCES += $(PWD)/generic/regfile.sv
VERILOG_SOURCES += $(PWD)/spi-axi/spi_axis_top.sv
VERILOG_SOURCES += $(PWD)/spi-axi/spi_slave.sv

TOPLEVEL = system_top
MODULE = tb_system_top
WAVES = 1

include $(shell cocotb-config --makefiles)/Makefile.sim
