MODULE := driver_controller

OBJS += tb_$(MODULE).o driver.o driver_cmd.o

-include base_testbench.mk

$(MODULE).simu: $(OBJS)
	$(LINK.o) $^ $(LOADLIBES) $(LDLIBS) $(TARGET_ARCH) -o $@

