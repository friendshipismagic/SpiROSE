#============================================================
# LED DRIVERS (DATA)
#============================================================
set_location_assignment PIN_236 -to drv_sin[0]
set_location_assignment PIN_231 -to drv_sin[1]
set_location_assignment PIN_41 -to drv_sin[10]
set_location_assignment PIN_43 -to drv_sin[11]
set_location_assignment PIN_37 -to drv_sin[12]
set_location_assignment PIN_24 -to drv_sin[13]
set_location_assignment PIN_38 -to drv_sin[14]
set_location_assignment PIN_83 -to drv_sin[15]
set_location_assignment PIN_78 -to drv_sin[16]
set_location_assignment PIN_80 -to drv_sin[17]
set_location_assignment PIN_69 -to drv_sin[18]
set_location_assignment PIN_55 -to drv_sin[19]
set_location_assignment PIN_232 -to drv_sin[2]
set_location_assignment PIN_68 -to drv_sin[20]
set_location_assignment PIN_200 -to drv_sin[21]
set_location_assignment PIN_197 -to drv_sin[22]
set_location_assignment PIN_201 -to drv_sin[23]
set_location_assignment PIN_196 -to drv_sin[24]
set_location_assignment PIN_188 -to drv_sin[25]
set_location_assignment PIN_194 -to drv_sin[26]
set_location_assignment PIN_186 -to drv_sin[27]
set_location_assignment PIN_185 -to drv_sin[28]
set_location_assignment PIN_187 -to drv_sin[29]
set_location_assignment PIN_224 -to drv_sin[3]
set_location_assignment PIN_217 -to drv_sin[4]
set_location_assignment PIN_221 -to drv_sin[5]
set_location_assignment PIN_49 -to drv_sin[6]
set_location_assignment PIN_45 -to drv_sin[7]
set_location_assignment PIN_51 -to drv_sin[8]
set_location_assignment PIN_44 -to drv_sin[9]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to drv_sin*

#============================================================
# LED DRIVERS (CONTROL)
#============================================================
set_location_assignment PIN_216 -to drv_sout_data
set_location_assignment PIN_214 -to fpga_gclk_a
set_location_assignment PIN_52 -to fpga_gclk_b
set_location_assignment PIN_226 -to fpga_lat_a
set_location_assignment PIN_70 -to fpga_lat_b
set_location_assignment PIN_218 -to fpga_sclk_a
set_location_assignment PIN_57 -to fpga_sclk_b

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to drv_sout_data
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to fpga_*
