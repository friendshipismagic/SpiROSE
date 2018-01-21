MODULE := framebuffer
DEPS := 

ROOT = tb_$(MODULE)
OBJS += $(ROOT)/main.o $(ROOT)/monitor.o

-include base_testbench.mk
