export SYSTEMC_INCLUDE ?= /usr/include/
export SYSTEMC_LIBDIR ?= /usr/lib/

SV_MODULE_PATH = ../src

VERILATOR = verilator
VERILATOR_ROOT ?= /usr/share/verilator/include/
VERILATOR_FLAGS = --sc --trace
VERILATOR_BASE = verilated.o verilated_vcd_c.o verilated_vcd_sc.o
VERILATOR_OBJS = \
	obj_dir/V$(MODULE).o obj_dir/V$(MODULE)__Syms.o \
	$(patsubst %,obj_dir/V%.o,$(DEPS)) $(patsubst %,obj_dir/V%__Syms.o,$(DEPS))

OBJS += $(VERILATOR_BASE) $(VERILATOR_OBJS)
DEPSFILES = $(subst .o,.d,$(OBJS))

all: $(MODULE).simu

LDFLAGS = -L$(SYSTEMC_LIBDIR)
LINK.o = g++ $(LDFLAGS) $(TARGET_ARCH)
LIBS = -lsystemc

VPATH = ../src/ ../src/systemc ../tb_src/ ../tb_src/systemc ./obj_dir/ $(VERILATOR_ROOT) ../lib

CPPFLAGS = -I../src/systemc/ \
		   -I./obj_dir/ \
		   -I../lib/ \
		   -I../tb_src/systemc/ \
		   -I$(VERILATOR_ROOT) \
		   -I$(SYSTEMC_INCLUDE)

CXXFLAGS = -DSC_INCLUDE_DYNAMIC_PROCESSES -g

obj_dir/V%.cpp obj_dir/V%__Syms.cpp obj_dir/V%.h: %.sv
	$(VERILATOR) $(VERILATOR_FLAGS) -y $(SV_MODULE_PATH) $<

%.d: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(TARGET_ARCH) -MM -MP $^ -MF $@

$(MODULE).simu: $(OBJS)
	$(LINK.o) $(filter %.o,$^) $(LOADLIBES) $(LIBS) $(TARGET_ARCH) -o $@

clean:
	rm -rf $(DEPSFILES) $(OBJS) $(MODULE).simu

-include $(DEPSFILES)

