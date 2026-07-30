SIM ?= icarus

TOPLEVEL_LANG ?= verilog

COMPILE_ARGS += -g2012

VERILOG_SOURCES += ../fwft_fifo.sv ../spi_slave.sv ../spi_axis_top.sv

TOPLEVEL = spi_axis_top

MODULE = tb_spi

WAVES = 1

include $(shell cocotb-config --makefiles)/Makefile.sim