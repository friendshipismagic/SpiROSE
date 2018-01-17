MODULE := spi_slave
DEPS := clock_lse

ROOT = tb_$(MODULE)
OBJS += $(ROOT)/main.o $(ROOT)/monitor.o

-include base_testbench.mk

$(MODULE).simu: $(OBJS)
	$(LINK.o) $(filter %.o,$^) $(LOADLIBES) $(LIBS) $(TARGET_ARCH) -o $@

