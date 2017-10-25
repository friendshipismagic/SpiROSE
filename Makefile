EXE = rose-renderer-poc
SRCDIR = src
CXXSRC = $(SRCDIR)/main.cpp

GCC_COLOR_MODE = auto
CXXFLAGS = -Wall -O2 -g -std=c++14 -iquote$(SRCDIR) -MMD -MP \
           -fdiagnostics-color=$(GCC_COLOR_MODE) -DGLM_FORCE_RADIANS

LDLIBS =
LDFLAGS = -flto

# Selects the abstraction library used to handle inputs, windowing, ...
# e.g. glfw3, sdl2, ...
WINDOW_BACKEND = glfw3
WINDOW_BACKEND_LIB = $(shell pkg-config --libs $(WINDOW_BACKEND) 2> /dev/null)

ifeq ($(OS),Windows_NT)
	CC = i686-w64-mingw32-c++
	CXX = i686-w64-mingw32-c++
	CXXFLAGS += -mwindows -D_USE_MATH_DEFINES

	WINDOW_BACKEND_LIB = -l$(WINDOW_BACKEND)
	LDLIBS += -lglew32 $(WINDOW_BACKEND_LIB) -lopengl32 -lgdi32
	LDFLAGS += -static-libstdc++ -static-libgcc

	CXXFLAGS += -DOS_WIN32
else
	CC = c++
	CXX = c++

	UNAME = $(shell uname -s)
	ifeq ($(UNAME),Linux)
		LDLIBS += $(WINDOW_BACKEND_LIB) -lGLEW -lm -lGL
		CXXFLAGS += -DOS_LINUX
	endif
	ifeq ($(UNAME),Darwin)
		LDLIBS += -framework OpenGL $(WINDOW_BACKEND_LIB)
		CXXFLAGS += -DOS_OSX
	endif
endif

CXXFLAGS += -DWINDOW_BACKEND_$(shell echo $(WINDOW_BACKEND) | tr '[:lower:]' '[:upper:]')

# Generated variables
OBJS = $(CXXSRC:.cpp=.o)
DEPS = $(CXXSRC:.cpp=.d)

.PHONY: all run clean

all: $(EXE)
$(EXE): $(OBJS)
	$(LINK.o) $^ $(LOADLIBES) $(LDLIBS) -o $@
-include $(DEPS)

run: $(EXE)
	./$(EXE)
clean:
	rm -f $(OBJS) $(DEPS) $(EXE)

.clang_complete: $(CXXSRC)
	$(MAKE) \
		CC="~/.vim/bin/cc_args.py $(CC)" \
		CXX="~/.vim/bin/cc_args.py $(CXX)" \
		-B -j$(shell grep -c "^processor" /proc/cpuinfo)

