SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/../../src/uart_programming/uart_rx.sv

TOPLEVEL = uart_rx

COCOTB_TEST_MODULES = uartrx_tb

WAVES=1

include $(shell cocotb-config --makefiles)/Makefile.sim