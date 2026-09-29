###############################################################################
# Created by write_sdc
###############################################################################
current_design system_top_pad_wrapper
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name clk -period 62.5000 [get_ports {clk}]
set_clock_transition 0.1500 [get_clocks {clk}]
set_clock_uncertainty 0.2500 clk
set_propagated_clock [get_clocks {clk}]
set_input_delay 0.0000 -clock [get_clocks {clk}] -min -add_delay [get_ports {cs_n}]
set_input_delay 12.5000 -clock [get_clocks {clk}] -max -add_delay [get_ports {cs_n}]
set_input_delay 0.0000 -clock [get_clocks {clk}] -min -add_delay [get_ports {mosi}]
set_input_delay 12.5000 -clock [get_clocks {clk}] -max -add_delay [get_ports {mosi}]
set_input_delay 0.0000 -clock [get_clocks {clk}] -min -add_delay [get_ports {rst_n}]
set_input_delay 12.5000 -clock [get_clocks {clk}] -max -add_delay [get_ports {rst_n}]
set_input_delay 0.0000 -clock [get_clocks {clk}] -min -add_delay [get_ports {sck}]
set_input_delay 12.5000 -clock [get_clocks {clk}] -max -add_delay [get_ports {sck}]
set_input_delay 0.0000 -clock [get_clocks {clk}] -min -add_delay [get_ports {uart_rx}]
set_input_delay 12.5000 -clock [get_clocks {clk}] -max -add_delay [get_ports {uart_rx}]
set_output_delay 12.5000 -clock [get_clocks {clk}] -add_delay [get_ports {miso_OUT}]
set_output_delay 12.5000 -clock [get_clocks {clk}] -add_delay [get_ports {miso_oe}]
###############################################################################
# Environment
###############################################################################
set_load -pin_load 0.0729 [get_ports {clk_PD}]
set_load -pin_load 0.0729 [get_ports {clk_PU}]
set_load -pin_load 0.0729 [get_ports {cs_n_PD}]
set_load -pin_load 0.0729 [get_ports {cs_n_PU}]
set_load -pin_load 0.0729 [get_ports {miso_CS}]
set_load -pin_load 0.0729 [get_ports {miso_IE}]
set_load -pin_load 0.0729 [get_ports {miso_OUT}]
set_load -pin_load 0.0729 [get_ports {miso_PD}]
set_load -pin_load 0.0729 [get_ports {miso_PU}]
set_load -pin_load 0.0729 [get_ports {miso_SL}]
set_load -pin_load 0.0729 [get_ports {miso_oe}]
set_load -pin_load 0.0729 [get_ports {mosi_PD}]
set_load -pin_load 0.0729 [get_ports {mosi_PU}]
set_load -pin_load 0.0729 [get_ports {rst_n_PD}]
set_load -pin_load 0.0729 [get_ports {rst_n_PU}]
set_load -pin_load 0.0729 [get_ports {sck_PD}]
set_load -pin_load 0.0729 [get_ports {sck_PU}]
set_load -pin_load 0.0729 [get_ports {uart_rx_PD}]
set_load -pin_load 0.0729 [get_ports {uart_rx_PU}]
###############################################################################
# Design Rules
###############################################################################
set_max_transition 2.5000 [current_design]
set_max_capacitance 0.4000 [current_design]
set_max_fanout 10.0000 [current_design]
