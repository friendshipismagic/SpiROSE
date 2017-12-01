TARGET = tb_driver
SYSTEMC_INCLUDE ?= /usr/include/
SYSTEMC_LIBDIR ?= /usr/lib/

SYSTEMC_MODULES_DIR = ../src/systemc/
FPGALIB = ../lib

CPPFLAGS = -I$(SYSTEMC_INCLUDE) -I$(SYSTEMC_MODULES_DIR) -I$(FPGALIB)
CXXFLAGS = -Wall -Wextra -Werror -std=c++11

LDFLAGS = -L"$(SYSTEMC_LIBDIR)" -L"$(FPGALIB)"
LDLIBS = -lsystemc

VPATH = $(SYSTEMC_MODULES_DIR)
vpath %.c ../lib

LINK.o = g++ $(LDFLAGS) $(TARGET_ARCH)

$(TARGET): tb_driver.o driver.o driver_cmd.o

build: $(TARGET)

test: $(TARGET)
	./$(TARGET)

clean:
	rm -rf *.o
	rm -rf $(TARGET)
