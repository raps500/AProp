set_global_assignment -entity "pll_altera" -library "lib_pll_altera" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll_altera" -library "lib_pll_altera" -name IP_TOOL_VERSION "13.0sp1"
set_global_assignment -entity "pll_altera" -library "lib_pll_altera" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll_altera" -name SPD_FILE [file join $::quartus(sip_path) "pll_altera.spd"]

set_global_assignment -library "lib_pll_altera" -name MISC_FILE [file join $::quartus(sip_path) "pll_altera_sim/pll_altera.vo"]
