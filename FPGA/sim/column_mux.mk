MODULE := column_mux
DEPS := clock_lse

ROOT = tb_$(MODULE)
OBJS += $(ROOT)/main.o $(ROOT)/monitor.o

-include base_testbench.mk
