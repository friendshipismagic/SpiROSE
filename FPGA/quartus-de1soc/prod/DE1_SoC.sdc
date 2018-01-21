#**************************************************************
# Altera DE1-SoC SDC settings
# Users are recommended to modify this file to match users logic.
#**************************************************************

#**************************************************************
# Create Clock
#**************************************************************
create_clock -period 20 [get_ports clock_50]
create_clock -period 20 [get_ports clock2_50]
create_clock -period 20 [get_ports clock3_50]
create_clock -period 20 [get_ports clock4_50]

create_clock -period "27 MHz"  -name tv_27m [get_ports td_clk27]
create_clock -period "100 MHz" -name clk_dram [get_ports dram_clk]
# AUDIO : 48kHz 384fs 32-bit data
#create_clock -period "18.432 MHz" -name clk_audxck [get_ports aud_xck]
#create_clock -period "1.536 MHz" -name clk_audbck [get_ports aud_bclk]
# VGA : 640x480@60Hz
create_clock -period "25.18 MHz" -name clk_vga [get_ports vga_clk]
# VGA : 800x600@60Hz
#create_clock -period "40.0 MHz" -name clk_vga [get_ports vga_clk]
# VGA : 1024x768@60Hz
#create_clock -period "65.0 MHz" -name clk_vga [get_ports vga_clk]
# VGA : 1280x1024@60Hz
#create_clock -period "108.0 MHz" -name clk_vga [get_ports vga_clk]

# for enhancing USB BlasterII to be reliable, 25MHz
create_clock -name {altera_reserved_tck} -period 40 {altera_reserved_tck}
set_input_delay -clock altera_reserved_tck -clock_fall 3 [get_ports altera_reserved_tdi]
set_input_delay -clock altera_reserved_tck -clock_fall 3 [get_ports altera_reserved_tms]
set_output_delay -clock altera_reserved_tck 3 [get_ports altera_reserved_tdo]

#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks

#**************************************************************
# Set Clock Latency
#**************************************************************
# Nothing
#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty

#**************************************************************
# Set Input Delay
#**************************************************************
# Board Delay (Data) + Propagation Delay - Board Delay (Clock)
set_input_delay -max -clock clk_dram -0.048 [get_ports dram_dq*]
set_input_delay -min -clock clk_dram -0.057 [get_ports dram_dq*]

set_input_delay -max -clock tv_27m 3.692 [get_ports td_data*]
set_input_delay -min -clock tv_27m 2.492 [get_ports td_data*]
set_input_delay -max -clock tv_27m 3.654 [get_ports td_hs]
set_input_delay -min -clock tv_27m 2.454 [get_ports td_hs]
set_input_delay -max -clock tv_27m 3.656 [get_ports td_vs]
set_input_delay -min -clock tv_27m 2.456 [get_ports td_vs]

#**************************************************************
# Set Output Delay
#**************************************************************
# max : Board Delay (Data) - Board Delay (Clock) + tsu (External Device)
# min : Board Delay (Data) - Board Delay (Clock) - th (External Device)
set_output_delay -max -clock clk_dram 1.452  [get_ports dram_dq*]
set_output_delay -min -clock clk_dram -0.857 [get_ports dram_dq*]
set_output_delay -max -clock clk_dram 1.531  [get_ports dram_addr*]
set_output_delay -min -clock clk_dram -0.805 [get_ports dram_addr*]
set_output_delay -max -clock clk_dram 1.533  [get_ports dram_*dqm]
set_output_delay -min -clock clk_dram -0.805 [get_ports dram_*dqm]
set_output_delay -max -clock clk_dram 1.510  [get_ports dram_ba*]
set_output_delay -min -clock clk_dram -0.800 [get_ports dram_ba*]
set_output_delay -max -clock clk_dram 1.520  [get_ports dram_ras_n]
set_output_delay -min -clock clk_dram -0.780 [get_ports dram_ras_n]
set_output_delay -max -clock clk_dram 1.5000 [get_ports dram_cas_n]
set_output_delay -min -clock clk_dram -0.800 [get_ports dram_cas_n]
set_output_delay -max -clock clk_dram 1.545  [get_ports dram_we_n]
set_output_delay -min -clock clk_dram -0.755 [get_ports dram_we_n]
set_output_delay -max -clock clk_dram 1.496  [get_ports dram_cke]
set_output_delay -min -clock clk_dram -0.804 [get_ports dram_cke]
set_output_delay -max -clock clk_dram 1.508  [get_ports dram_cs_n]
set_output_delay -min -clock clk_dram -0.792 [get_ports dram_cs_n]

set_output_delay -max -clock clk_vga 0.220  [get_ports vga_r*]
set_output_delay -min -clock clk_vga -1.506 [get_ports vga_r*]
set_output_delay -max -clock clk_vga 0.212  [get_ports vga_g*]
set_output_delay -min -clock clk_vga -1.519 [get_ports vga_g*]
set_output_delay -max -clock clk_vga 0.264  [get_ports vga_b*]
set_output_delay -min -clock clk_vga -1.519 [get_ports vga_b*]
set_output_delay -max -clock clk_vga 0.215  [get_ports vga_blank_n]
set_output_delay -min -clock clk_vga -1.485 [get_ports vga_blank_n]

#**************************************************************
# Set Clock Groups
#**************************************************************

#**************************************************************
# Set False Path
#**************************************************************
set_false_path -from [get_ports key*] -to *
set_false_path -from [get_ports sw*] -to *
set_false_path -from * -to [get_ports led* ]
set_false_path -from * -to [get_ports hex* ]

#**************************************************************
# Set Multicycle Path
#**************************************************************

#**************************************************************
# Set Maximum Delay
#**************************************************************

#**************************************************************
# Set Minimum Delay
#**************************************************************

#**************************************************************
# Set Input Transition
#**************************************************************

#**************************************************************
# Set Load
#**************************************************************
