EXE = rose-renderer-poc
SRCDIR = src
CXXSRC = $(SRCDIR)/main.cpp $(SRCDIR)/tiny_obj_loader.cpp

GCC_COLOR_MODE = auto
CXXFLAGS = -Wall -O2 -g -std=c++14 -iquote$(SRCDIR) -MMD -MP \
           -fdiagnostics-color=$(GCC_COLOR_MODE) -DGLM_FORCE_RADIANS \
           -isystem./lib

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

RUNFLAGS = -x

run: $(EXE)
	./$(EXE) $(RUNFLAGS)
clean:
	rm -f $(OBJS) $(DEPS) $(EXE)

lint:
	find . \( -regex '.*\.[vgf]s' -or -regex '.*\.[ch]\(pp\)*' \) -not -path './lib*' -exec clang-format -i '{}' \;
	git status --porcelain | grep -e "^ M" && exit 1 || exit 0
build: all
test:
	@echo "Test"
host:
	@echo "Host"

