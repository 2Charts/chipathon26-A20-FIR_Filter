## Track: A <br>Team: A20 MisterKebab<br>Project: 16-bit Programmable Symmetric FIR Filter

## Team Members
|Discord|Github|Affiliation|Role|
|-|-|-|-|
|2Charts|[@2Charts](https://github.com/2Charts)|Bandung Institute of Technology, Indonesia (Undergraduate)|Team Lead|
|Bived|[@AlfatihahNW](https://github.com/AlfatihahNW)|Bandung Institute of Technology, Indonesia (Undergraduate)|Team Member|
|Jk.|[@Jekk1213](https://github.com/jekk1213)|Bandung Institute of Technology, Indonesia (Undergraduate)|Team Member|
|Cliff|[@kiffot](https://github.com/kiffot)|Bandung Institute of Technology, Indonesia (Undergraduate)|Team Member|

Overview: This project proposes a 16-bit programmable FIR filter with an integrated SPI and UART configuration interface. The architecture uses a folded Multiply-Accumulate (MAC) DSP design with a dynamically configurable delay line. It supports up to 32 taps for Symmetric and Anti-Symmetric modes, and 16 taps for Asymmetric modes. Coefficients are programmable via a 115200-baud UART interface, while high-speed sample data is streamed via SPI over AXI-Stream.

Size: 1100µm x 550µm (GF180MCU)
Required Pins: 8 (clk, rst_n, sck, cs_n, mosi, miso, miso_oe, uart_rx)

Links
[Project Repository](https://github.com/2Charts/chipathon26-A20-FIR_Filter)
Project Proposal :  TBD
