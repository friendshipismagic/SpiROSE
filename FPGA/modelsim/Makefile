# Simulation working directory
WORK_DIR = work

# Top level directory
TOP_DIR = ..

# Top level file for simulation (testbench)
TB_TOP = driver_testbench

# Include directory
INCDIR = ${TOP_DIR}/src

# Include all SystemVerilog and Verilog files
SRCS = driver_controller.sv \
	   framebuffer_emulator.sv \
	   clock_lse_inverse.sv \
	   clock_lse.sv \
	   column_mux.sv \
	   driver_testbench.sv
#$(wildcard ${TOP_DIR}/src/*.sv ${TOP_DIR}/tb_src/*.sv ${TOP_DIR}/src/*.v ${TOP_DIR}/tb_src/*.v)

vpath %.sv ${TOP_DIR}/src
vpath %.sv ${TOP_DIR}/tb_src

# Put everything into working directory with extension .compiled
# (TODO: Name collision to remove)
TRGTS = $(addprefix ${WORK_DIR}/,$(notdir $(SRCS:%.sv=.%.compiled)))

# By default, simulate without GUI
all: simu_batch

# Command-line simulation, 1ps per tick
simu_batch: build
	cd $(WORK_DIR) ; vsim  -batch -t 1ps -lib work -L altera_lnsim_ver $(TB_TOP) -do "run -all ; quit"

# GUI simulation, 1ps per tick
simu_gui: build
	cd $(WORK_DIR); vsim -t 1ps -lib work -L altera_lnsim_ver $(TB_TOP)

# Build
build: $(TRGTS)

# Build recipe
$(WORK_DIR)/.%.compiled: %.sv | $(WORK_DIR)
	cd $(WORK_DIR) ; vlog +incdir+../${INCDIR}  +acc +define+SIMULATION -timescale "1ns/1ps" ../$<
	touch $@

# Create the working directory if it does not exist
$(WORK_DIR):
	mkdir $(WORK_DIR)

# Remove workdir
clean:
	$(RM) -r $(WORK_DIR)

# Virtual recipes
.PHONY: clean all simu_batch build simu_gui info
