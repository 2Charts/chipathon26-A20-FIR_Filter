#!/bin/bash
set -e

echo "Starting Gate-Level Simulation setup..."

# Check if PDK exists, clone if it doesn't
if [ ! -d "gf180mcu" ]; then
    echo "PDK not found. Cloning gf180mcu..."
    make clone-pdk
fi

echo "Compiling Gate-Level Simulation with Icarus Verilog..."
iverilog -g2012 -gspecify \
    -DFUNCTIONAL -DUSE_POWER_PINS -DGL_SIM \
    -I src/ \
    -I gf180mcu/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/verilog \
    gf180mcu/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/verilog/gf180mcu_fd_sc_mcu7t5v0.v \
    gf180mcu/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/verilog/primitives.v \
    final/pnl/system_top.pnl.v \
    src/tb_system_top.sv \
    -o gl_sim.vvp

echo "Running simulation..."
vvp gl_sim.vvp

echo "Simulation complete! You can view the waveform using:"
echo "gtkwave waveform_sys.vcd"
