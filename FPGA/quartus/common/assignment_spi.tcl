#============================================================
# SPI CONNECTION WITH THE SBC
#============================================================
set_location_assignment PIN_9 -to som_cs
set_location_assignment PIN_240 -to som_miso
set_location_assignment PIN_239 -to som_mosi
set_location_assignment PIN_6 -to som_sclk

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to som_cs
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to som_miso
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to som_mosi
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to som_sclk

