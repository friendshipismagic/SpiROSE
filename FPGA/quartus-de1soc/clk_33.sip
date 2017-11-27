set_global_assignment -entity "clk_33" -library "lib_clk_33" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "clk_33" -library "lib_clk_33" -name IP_TOOL_VERSION "17.0"
set_global_assignment -entity "clk_33" -library "lib_clk_33" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_clk_33" -name SPD_FILE [file join $::quartus(sip_path) "clk_33.spd"]

set_global_assignment -library "lib_clk_33" -name MISC_FILE [file join $::quartus(sip_path) "clk_33_sim/clk_33.vo"]
