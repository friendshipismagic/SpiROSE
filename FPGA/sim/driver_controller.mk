MODULE := driver_controller
DEPS := clock_enable

ROOT = tb_$(MODULE)
OBJS += $(ROOT)/main.o $(ROOT)/monitor.o driver.o driver_cmd.o

-include base_testbench.mk
