MODULE := spi_iff
DEPS := spi_decoder

ROOT = tb_$(MODULE)
OBJS += $(ROOT)/main.o $(ROOT)/monitor.o

-include base_testbench.mk
