set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 1
set_global_assignment -name NOMINAL_CORE_SUPPLY_VOLTAGE 1.2V
set_global_assignment -name STRATIX_DEVICE_IO_STANDARD "2.5 V"

set_global_assignment -name DEVICE_FILTER_PACKAGE "ANY QFP"
set_global_assignment -name DEVICE_FILTER_PIN_COUNT 240
set_global_assignment -name STRATIX_DEVICE_IO_STANDARD "3.0-V LVCMOS"
set_global_assignment -name CYCLONEIII_CONFIGURATION_SCHEME "PASSIVE SERIAL"
set_global_assignment -name USE_CONFIGURATION_DEVICE OFF
set_global_assignment -name CRC_ERROR_OPEN_DRAIN OFF
set_global_assignment -name GENERATE_JAM_FILE ON
set_global_assignment -name FORCE_CONFIGURATION_VCCIO ON
set_global_assignment -name RESERVE_ALL_UNUSED_PINS_WEAK_PULLUP "AS INPUT TRI-STATED"
set_global_assignment -name RESERVE_DATA7_THROUGH_DATA2_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name RESERVE_FLASH_NCE_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name OUTPUT_IO_TIMING_NEAR_END_VMEAS "HALF VCCIO" -rise
set_global_assignment -name OUTPUT_IO_TIMING_NEAR_END_VMEAS "HALF VCCIO" -fall
set_global_assignment -name OUTPUT_IO_TIMING_FAR_END_VMEAS "HALF SIGNAL SWING" -rise
set_global_assignment -name OUTPUT_IO_TIMING_FAR_END_VMEAS "HALF SIGNAL SWING" -fall
set_global_assignment -name RESERVE_DATA0_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name RESERVE_DATA1_AFTER_CONFIGURATION "USE AS REGULAR IO"

set_global_assignment -name VERILOG_INPUT_VERSION SYSTEMVERILOG_2005
set_global_assignment -name VERILOG_SHOW_LMF_MAPPING_MESSAGES OFF
set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "NO HEAT SINK WITH 400 LFPM AIRFLOW"
set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"
set_global_assignment -name TIMEQUEST_MULTICORNER_ANALYSIS ON
set_global_assignment -name NUM_PARALLEL_PROCESSORS ALL
set_global_assignment -name FLOW_ENABLE_IO_ASSIGNMENT_ANALYSIS ON
set_global_assignment -name EDA_DESIGN_ENTRY_SYNTHESIS_TOOL "<None>"
set_global_assignment -name EDA_INPUT_DATA_FORMAT EDIF -section_id eda_design_synthesis
set_global_assignment -name EDA_SIMULATION_TOOL "ModelSim (SystemVerilog)"
set_global_assignment -name EDA_OUTPUT_DATA_FORMAT "SYSTEMVERILOG HDL" -section_id eda_simulation
set_global_assignment -name EDA_FORMAL_VERIFICATION_TOOL "<None>"
set_global_assignment -name EDA_BOARD_DESIGN_TIMING_TOOL "Stamp (Timing)"
set_global_assignment -name EDA_OUTPUT_DATA_FORMAT STAMP -section_id eda_board_design_timing
set_global_assignment -name EDA_BOARD_DESIGN_SYMBOL_TOOL "<None>"
set_global_assignment -name EDA_OUTPUT_DATA_FORMAT NONE -section_id eda_board_design_symbol
set_global_assignment -name EDA_BOARD_DESIGN_SIGNAL_INTEGRITY_TOOL "IBIS (Signal Integrity)"
set_global_assignment -name EDA_OUTPUT_DATA_FORMAT IBIS -section_id eda_board_design_signal_integrity
set_global_assignment -name EDA_BOARD_DESIGN_BOUNDARY_SCAN_TOOL "<None>"
set_global_assignment -name EDA_OUTPUT_DATA_FORMAT NONE -section_id eda_board_design_boundary_scan
set_global_assignment -name EDA_TIME_SCALE "1 ps" -section_id eda_simulation
set_global_assignment -name VHDL_SHOW_LMF_MAPPING_MESSAGES OFF

set_global_assignment -name SMART_RECOMPILE ON
set_global_assignment -name DISABLE_OCP_HW_EVAL ON
set_global_assignment -name CYCLONEII_OPTIMIZATION_TECHNIQUE SPEED
set_global_assignment -name SYNTH_TIMING_DRIVEN_SYNTHESIS ON
set_global_assignment -name DEVICE_FILTER_SPEED_GRADE 8
set_global_assignment -name ENABLE_INIT_DONE_OUTPUT OFF
set_global_assignment -name GENERATE_JBC_FILE ON
set_global_assignment -name CONFIGURATION_VCCIO_LEVEL 3.0V

set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id Top
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id Top
set_global_assignment -name PARTITION_COLOR 16764057 -section_id Top


set_global_assignment -name CYCLONEII_RESERVE_NCEO_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name RESERVE_DCLK_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name ENABLE_CONFIGURATION_PINS OFF
set_global_assignment -name ENABLE_NCE_PIN OFF
set_global_assignment -name ENABLE_BOOT_SEL_PIN OFF

set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../common/assignment_drivers.tcl
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../common/assignment_encoder.tcl
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../common/assignment_hall.tcl
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../common/assignment_lvds.tcl
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../common/assignment_mux.tcl
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../common/assignment_pt.tcl
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../common/assignment_rgb.tcl
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../common/assignment_spi.tcl
