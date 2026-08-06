## CLOCK (100 MHz onboard oscillator)
set_property PACKAGE_PIN E3 [get_ports {clk}]
set_property IOSTANDARD LVCMOS33 [get_ports {clk}]
create_clock -period 10.0 [get_ports {clk}]

## RESET BUTTON (BTNC)
set_property PACKAGE_PIN C12 [get_ports {reset}]
set_property IOSTANDARD LVCMOS33 [get_ports {reset}]

## Switch 0 (mode select)
set_property PACKAGE_PIN J15 [get_ports {sw0}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw0}]

## LEDs
set_property PACKAGE_PIN H17 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN K15 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

set_property PACKAGE_PIN J13 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]

set_property PACKAGE_PIN N14 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]