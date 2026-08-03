SIM ?= icarus
TOPLEVEL_LANG ?= verilog
PWD = $(shell pwd)

VERILOG_SOURCES += $(PWD)/../programmer.sv
VERILOG_SOURCES += $(PWD)/../uart_rx.sv
VERILOG_SOURCES += $(PWD)/../../generic/fwft_fifo.sv

TOPLEVEL = programmer
COCOTB_TEST_MODULES   = tb_programmer

COMPILE_ARGS += -Pprogrammer.CLK_FREQ=50000000 #example just for test
COMPILE_ARGS += -Pprogrammer.BAUD_RATE=115200  #example just for test
COMPILE_ARGS += -Pprogrammer.TIMEOUT_MS=5 #example just for test      

WAVES = 1

include $(shell cocotb-config --makefiles)/Makefile.sim