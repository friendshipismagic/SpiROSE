#============================================================
# LED MUX
#============================================================
set_location_assignment PIN_207 -to fpga_mul_a[0]
set_location_assignment PIN_230 -to fpga_mul_a[1]
set_location_assignment PIN_56 -to fpga_mul_a[2]
set_location_assignment PIN_46 -to fpga_mul_a[3]
set_location_assignment PIN_235 -to fpga_mul_a[4]
set_location_assignment PIN_219 -to fpga_mul_a[5]
set_location_assignment PIN_50 -to fpga_mul_a[6]
set_location_assignment PIN_39 -to fpga_mul_a[7]
set_location_assignment PIN_63 -to fpga_mul_b[0]
set_location_assignment PIN_76 -to fpga_mul_b[1]
set_location_assignment PIN_203 -to fpga_mul_b[2]
set_location_assignment PIN_184 -to fpga_mul_b[3]
set_location_assignment PIN_84 -to fpga_mul_b[4]
set_location_assignment PIN_73 -to fpga_mul_b[5]
set_location_assignment PIN_202 -to fpga_mul_b[6]
set_location_assignment PIN_189 -to fpga_mul_b[7]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to fpga_mul_*

