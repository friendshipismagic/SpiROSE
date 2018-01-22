LINTER=verilator
LINTER_ARGS=--lint-only -Wall

SRCS=$(wildcard src/*.sv)

$(SRCS):

%.sv.lint:
	$(LINTER) $(LINTER_ARGS) $* -y src

lint: $(addsuffix .lint,$(SRCS))
	@echo "Running lint tests"
	make -C lib -f driver_cmd.mk lint
	make -C tb_sc -f tb_driver.mk lint

build :
	@echo "Building fpga target"
	make -C lib -f driver_cmd.mk build

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
