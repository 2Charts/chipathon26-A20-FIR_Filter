SIM ?= icarus
TOPLEVEL_LANG ?= verilog
PWD = $(shell pwd)

VERILOG_SOURCES += $(PWD)/../../src/uart_programming/programmer.sv
VERILOG_SOURCES += $(PWD)/../../src/uart_programming/uart_rx.sv
VERILOG_SOURCES += $(PWD)/../../src/generic/fwft_fifo.sv

TOPLEVEL = programmer
COCOTB_TEST_MODULES   = tb_programmer

COMPILE_ARGS += -Pprogrammer.CLK_FREQ=16000000 #example just for test
COMPILE_ARGS += -Pprogrammer.BAUD_RATE=115200  #example just for test
COMPILE_ARGS += -Pprogrammer.TIMEOUT_MS=5 #example just for test      

WAVES = 1

include $(shell cocotb-config --makefiles)/Makefile.sim