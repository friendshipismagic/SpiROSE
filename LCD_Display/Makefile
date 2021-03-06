# Possible Targets:	all clean Debug cleanDebug Release cleanRelease

##############################################################################################
# Settings
#

# General settings
	# See $(GFXLIB)/tools/gmake_scripts/readme.txt for the list of variables
	OPT_OS					= raw32
	OPT_THUMB				= yes
	OPT_LINK_OPTIMIZE		= no
	OPT_CPU					= stm32m7

# uGFX settings
	# See $(GFXLIB)/tools/gmake_scripts/library_ugfx.mk for the list of variables
	GFXLIB					= ugfx
	GFXBOARD				= STM32F746-Discovery
	GFXDEMO					= 
	#GFXDRIVERS				=
	GFXSINGLEMAKE			= no
	GFXSRC +=

# ChibiOS settings
ifeq ($(OPT_OS),chibios)
	# See $(GFXLIB)/tools/gmake_scripts/os_chibios_3.mk for the list of variables
	CHIBIOS					= ../ChibiOS_17.6.1
	CHIBIOS_VERSION			= 3
	CHIBIOS_CPUCLASS		= ARMCMx
	CHIBIOS_PLATFORM		= STM32
	CHIBIOS_DEVICE_FAMILY	= STM32F7xx
	CHIBIOS_STARTUP			= startup_stm32f7xx
	CHIBIOS_PORT			= v7m
	CHIBIOS_LDSCRIPT		= STM32F746xG.ld
	CHIBIOS_BOARD			= ST_STM32F746G_DISCOVERY
	#CHIBIOS_PROCESS_STACKSIZE = 0x400
	#CHIBIOS_EXCEPTIONS_STACKSIZE = 0x400
endif

#Special - Required for the drivers for this discovery board.
STMHAL		= STM32/STM32F7xx_HAL_Driver

#Special - Required for Raw32
#CMSIS			= ../STM32/CMSIS

##############################################################################################
# Set these for your project
#

ARCH     = arm-none-eabi-
SRCFLAGS = -ggdb -O1
#The following flags are used only for libraries
CFLAGS   = -Wno-duplicate-decl-specifier -Wno-misleading-indentation -Wno-unused-parameter
#CPROJECT_FLAGS is specific to the user source files to treat warnings as error
PROJECT_FLAGS = -Werror
CXXFLAGS = -fno-rtti
ASFLAGS  =
LDFLAGS  = --specs=rdimon.specs   -Wl,--start-group -lgcc -lc -lm -lrdimon -Wl,--end-group

SRC      = main.c widget.c

OBJS     =
DEFS     = GFX_OS_HEAP_SIZE=40960
#DEFS     = 
LIBS     =
INCPATH  = Include

LIBPATH  =
LDSCRIPT =

# For user source c files, compile with warning treated as errors and with all warnings
OBJDIR = .build/obj
$(OBJDIR)/$(SRC:.c=.o): CFLAGS = $(PROJECT_FLAGS)

##############################################################################################
# These should be at the end
#

include $(GFXLIB)/tools/gmake_scripts/library_ugfx.mk
include $(GFXLIB)/tools/gmake_scripts/os_$(OPT_OS).mk
include $(GFXLIB)/tools/gmake_scripts/compiler_gcc.mk

lint:
	@echo "Running lint tests"
	# TODO: move files into a subdir to do recursive globbing
	clang-format -i *.c *.h
	git status --porcelain | grep -e "^ M" && exit 1 || exit 0

test:
	@echo "Running lower base tests"

host:
	@echo "Running lower base host tests"

# *** EOF ***
