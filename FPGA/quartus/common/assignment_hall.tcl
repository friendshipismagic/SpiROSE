#============================================================
# HALL SENSORS
#============================================================
set_location_assignment PIN_12 -to hall[0]
set_location_assignment PIN_22 -to hall[1]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hall*

