SRC_DIR=src
TOP_LEVEL=top_module.sv
LINTER=verilator
LINTER_ARGS=--lint-only -Wall

lint:
	@echo "Running lint tests"
	make -C lib -f driver_cmd.mk lint
	$(LINTER) $(LINTER_ARGS) $(TOP_LEVEL) -y $(SRC_DIR)
	make -C tb_sc -f tb_driver.mk lint

build :
	@echo "Building fpga target"
	make -C lib -f driver_cmd.mk build
	make -C tb_sc -f tb_driver.mk build
	make -C sim build

test:
	@echo "Running fpga tests"
	make -C lib -f driver_cmd.mk test
	make -C tb_sc -f tb_driver.mk test
	make -C sim sim

host:
	@echo "Running fpga host tests"

clean:
	make -C sim clean
	make -C lib -f driver_cmd.mk clean
	make -C tb_sc -f tb_driver.mk clean

.PHONY: build lint test host clean
