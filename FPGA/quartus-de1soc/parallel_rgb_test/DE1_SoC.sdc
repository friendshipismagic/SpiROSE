#**************************************************************
# Altera DE1-SoC SDC settings
# Users are recommended to modify this file to match users logic.
#**************************************************************

#**************************************************************
# Create Clock
#**************************************************************
create_clock -period 20 [get_ports clock_50]

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
