MODULE := driver_controller
DEPS := clock_lse

OBJS += tb_driver_controller.o driver.o driver_cmd.o

-include base_testbench.mk

$(MODULE).simu: $(OBJS)
	$(LINK.o) $(filter %.o,$^) $(LOADLIBES) $(LIBS) $(TARGET_ARCH) -o $@

