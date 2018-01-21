#============================================================
# LVDS DISPLAY
#============================================================
set_location_assignment PIN_99 -to lvds_tx_n[0]
set_location_assignment PIN_94 -to lvds_tx_n[1]
set_location_assignment PIN_88 -to lvds_tx_n[2]
set_location_assignment PIN_82 -to lvds_tx_n[3]
set_location_assignment PIN_98 -to lvds_tx_p[0]
set_location_assignment PIN_93 -to lvds_tx_p[1]
set_location_assignment PIN_87 -to lvds_tx_p[2]
set_location_assignment PIN_81 -to lvds_tx_p[3]

set_instance_assignment -name IO_STANDARD "3.0V LVCMOS" -to lvds_tx_*

