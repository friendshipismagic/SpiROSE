#============================================================
# RGB PARALLEL DISPLAY
#============================================================
set_location_assignment PIN_171 -to rgb_clk2
set_location_assignment PIN_152 -to rgb_clk
set_location_assignment PIN_100 -to rgb_d[0]
set_location_assignment PIN_103 -to rgb_d[1]
set_location_assignment PIN_128 -to rgb_d[10]
set_location_assignment PIN_131 -to rgb_d[11]
set_location_assignment PIN_132 -to rgb_d[12]
set_location_assignment PIN_134 -to rgb_d[13]
set_location_assignment PIN_135 -to rgb_d[14]
set_location_assignment PIN_137 -to rgb_d[15]
set_location_assignment PIN_143 -to rgb_d[16]
set_location_assignment PIN_144 -to rgb_d[17]
set_location_assignment PIN_145 -to rgb_d[18]
set_location_assignment PIN_159 -to rgb_d[19]
set_location_assignment PIN_106 -to rgb_d[2]
set_location_assignment PIN_160 -to rgb_d[20]
set_location_assignment PIN_162 -to rgb_d[21]
set_location_assignment PIN_164 -to rgb_d[22]
set_location_assignment PIN_166 -to rgb_d[23]
set_location_assignment PIN_111 -to rgb_d[3]
set_location_assignment PIN_112 -to rgb_d[4]
set_location_assignment PIN_113 -to rgb_d[5]
set_location_assignment PIN_117 -to rgb_d[6]
set_location_assignment PIN_118 -to rgb_d[7]
set_location_assignment PIN_126 -to rgb_d[8]
set_location_assignment PIN_127 -to rgb_d[9]
set_location_assignment PIN_176 -to rgb_hsync
set_location_assignment PIN_183 -to rgb_vsync


set_instance_assignment -name IO_STANDARD "3.0V LVCMOS" -to rgb_*

