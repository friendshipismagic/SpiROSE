export SYSTEMC_INCLUDE ?= /usr/include/
export SYSTEMC_LIBDIR ?= /usr/lib/

MODULES := driver_controller framebuffer column_mux rgb_logic spi_iff

SIMULATIONS = $(addsuffix .simu,$(MODULES))
TESTS = $(addsuffix .test,$(MODULES))

.PHONY: sim gen clean

sim: $(TESTS)
test: sim

gen: $(addsuffix .gen,$(SIMULATIONS))
build: gen

%.test: %.simu.gen
	./$*.simu

%.simu.gen:
	@echo "== Generate simulation for $* =="
	mkdir -p tb_$*
	make -f $*.mk $*.simu

clean: $(addsuffix .clean,$(MODULES))
	rm -rf obj_dir/
	rm -f $(SIMULATIONS)
	rm -f *.o *.d

%.clean:
	make -f $*.mk clean
