export SYSTEMC_INCLUDE ?= /usr/include/
export SYSTEMC_LIBDIR ?= /usr/lib/

MODULES =

SIMULATIONS = $(addsuffix .simu,$(MODULES))
TESTS = $(addsuffix .test,$(MODULES))

.PHONY: sim gen clean

sim: $(TESTS)
test: sim

gen: $(addsuffix .gen,$(SIMULATIONS))

%.test: %.simu.gen
	./$*.simu

%.simu.gen:
	@echo "== Generate simulation for $* =="
	make -f $*.mk $*.simu

clean:
	rm -rf obj_dir/
	rm -f $(SIMULATIONS)
	rm -f *.o *.d
