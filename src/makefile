# Default simulator
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
COMPILE_ARGS += -g2012

# Source files
VERILOG_SOURCES += $(PWD)/system_top.sv
VERILOG_SOURCES += $(PWD)/mac/mac.sv
VERILOG_SOURCES += $(PWD)/Delay\ Line/delay_line.sv
VERILOG_SOURCES += $(PWD)/uart/uartrx.sv
VERILOG_SOURCES += $(PWD)/FIR/fir_controller.sv
VERILOG_SOURCES += $(PWD)/FIR/fir_config_regs.sv
VERILOG_SOURCES += $(PWD)/spi/spi_axi_top.sv
VERILOG_SOURCES += $(PWD)/spi/spi_slave.sv
VERILOG_SOURCES += $(PWD)/spi/dual_clock_fifo.sv

TOPLEVEL = system_top
MODULE = tb_system_top

include $(shell cocotb-config --makefiles)/Makefile.sim
