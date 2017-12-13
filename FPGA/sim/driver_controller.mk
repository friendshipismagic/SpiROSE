MODULE := driver_controller
DEPS := clock_lse

ROOT = tb_$(MODULE)
OBJS += $(ROOT)/main.o driver.o driver_cmd.o


$(MODULE).simu: $(OBJS)
	$(LINK.o) $(filter %.o,$^) $(LOADLIBES) $(LIBS) $(TARGET_ARCH) -o $@

-include base_testbench.mk
