SRC_DIR=src
TOP_LEVEL=top.sv

lint:
	@echo "Running lint tests"
	make -C lib -f driver_cmd.mk lint
	@verilator --lint-only $(TOP_LEVEL) -y $(SRC_DIR)

build :
	@echo "Building fpga target"
	make -C lib -f driver_cmd.mk build
	make -C sim build

test:
	@echo "Running fpga tests"
	make -C lib -f driver_cmd.mk test
	make -C sim sim

host:
	@echo "Running fpga host tests"

clean:
	make -C sim clean
	make -C lib -f driver_cmd.mk clean

.PHONY: build lint test host clean
