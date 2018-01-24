set_global_assignment -entity "clk_66" -library "lib_clk_66" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "clk_66" -library "lib_clk_66" -name IP_TOOL_VERSION "17.0"
set_global_assignment -entity "clk_66" -library "lib_clk_66" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_clk_66" -name SPD_FILE [file join $::quartus(sip_path) "clk_66.spd"]

set_global_assignment -library "lib_clk_66" -name MISC_FILE [file join $::quartus(sip_path) "clk_66_sim/clk_66.vo"]
