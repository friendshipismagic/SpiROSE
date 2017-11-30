export SYSTEMC_INCLUDE ?= /usr/include/
export SYSTEMC_LIBDIR ?= /usr/lib/

SV_MODULE_PATH = ../src

VERILATOR = verilator
VERILATOR_ROOT ?= /usr/share/verilator/include/
VERILATOR_FLAGS = --sc --trace
VERILATOR_BASE = verilated.o verilated_vcd_c.o verilated_vcd_sc.o
VERILATOR_OBJS = obj_dir/V$(MODULE).o obj_dir/V$(MODULE)__Syms.o

OBJS += $(VERILATOR_BASE) $(VERILATOR_OBJS)

DEPS = $(subst .o,.d,$(OBJS))

deps:
	echo $(DEPS)

LDFLAGS = -L$(SYSTEMC_LIBDIR)
LINK.o = g++ $(LDFLAGS) $(TARGET_ARCH)
LDLIBS = -lsystemc

VPATH = ../src/ ../src/systemc ../tb_src/ ../tb_src/systemc ./obj_dir/ $(VERILATOR_ROOT) ../lib
export VPATH

CPPFLAGS = -I../src/systemc/ \
		   -I./obj_dir/ \
		   -I../lib/ \
		   -I$(VERILATOR_ROOT) \
		   -I$(SYSTEMC_INCLUDE)

CXXFLAGS = -DSC_INCLUDE_DYNAMIC_PROCESSES -g

export CPPFLAGS

obj_dir/V$(MODULE).h: $(MODULE).sv
	$(VERILATOR) $(VERILATOR_FLAGS) -y $(SV_MODULE_PATH) $<

obj_dir/V$(MODULE)__Syms.cpp obj_dir/V$(MODULE).cpp: obj_dir/V$(MODULE).h

%.d: %.cpp
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(TARGET_ARCH) -MM -MP $^ -MF $@

-include $(DEPS)
