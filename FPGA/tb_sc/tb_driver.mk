TARGET = tb_driver
SYSTEMC_INCLUDE ?= /usr/include/
SYSTEMC_LIBDIR ?= /usr/lib/

SYSTEMC_MODULES_DIR = ../src/systemc/
FPGALIB = ../lib

CPPFLAGS = -I$(SYSTEMC_INCLUDE) -I$(SYSTEMC_MODULES_DIR) -I$(FPGALIB)
CXXFLAGS = -Wall -Wextra -Werror -std=c++11 -g

LDFLAGS = -L"$(SYSTEMC_LIBDIR)" -L"$(FPGALIB)"
LDLIBS = -lsystemc

VPATH = $(SYSTEMC_MODULES_DIR)
vpath %.c ../lib

LINK.o = g++ $(LDFLAGS) $(TARGET_ARCH)

OBJ = tb_driver.o driver.o driver_cmd.o

$(TARGET): $(OBJ)
	g++ -g $(LDFLAGS) -o $@ $(OBJ) $(LDLIBS)

driver_cmd.o: $(FPGALIB)/driver_cmd.c
	gcc -Werror -Wall -Wextra -g -c $< -o $@

lint:
	clang-format -i *.cpp
	git status --porcelain | grep -e "^ M" && exit 1 || exit 0	

build: $(TARGET)

test: $(TARGET)
	./$(TARGET)

clean:
	rm -rf *.o
	rm -rf $(TARGET)
