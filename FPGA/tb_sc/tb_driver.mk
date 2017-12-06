SYSTEMC_INCLUDE ?= /usr/include/
SYSTEMC_LIB ?=  /usr/lib/

SYSTEMC_MODULES_DIR = ../src/systemc/

CPPFLAGS = -I$(SYSTEMC_INCLUDE) -L$(SYSTEMC_LIB) -I$(SYSTEMC_MODULES_DIR)
CXXFLAGS = -Wall -Wextra -Werror -std=c++11

LDFLAGS = -lsystemc -lstdc++

VPATH = ../src/systemc

tb_driver: tb_driver.o driver.o
