SONAME = libSpiROSE.so
SRCDIR = src
CXXSRC = $(SRCDIR)/spirose.cpp \
         $(SRCDIR)/context.cpp \
         $(SRCDIR)/object.cpp

GCC_COLOR_MODE = auto
CXXFLAGS = -Wall -O2 -g -std=c++14 -iquote$(SRCDIR) -MMD -MP \
           -fdiagnostics-color=$(GCC_COLOR_MODE) -DGLM_FORCE_RADIANS -fpic

# Allow to disable geometry shader at build time
ifeq ($(NO_GEOMETRY_SHADER),yes)
    CXXFLAGS += -DNO_GEOMETRY_SHADER
endif


LDLIBS =
LDFLAGS = -flto -shared -Wl,-install_name,$(SONAME)

ifeq ($(OS),Windows_NT)
	CC = i686-w64-mingw32-c++
	CXX = i686-w64-mingw32-c++
	CXXFLAGS += -mwindows -D_USE_MATH_DEFINES

	LDLIBS += -lglew32 -lglfw3 -lopengl32 -lgdi32
	LDFLAGS += -static-libstdc++ -static-libgcc

	CXXFLAGS += -DOS_WIN32
else
	CC = c++
	CXX = c++

	LDLIBS += $(shell pkg-config --libs glfw3 2> /dev/null)

	UNAME = $(shell uname -s)
	ifeq ($(UNAME),Linux)
		UNAME_P := $(shell uname -p)
		LDLIBS += -lm
		CXXFLAGS += -DOS_LINUX

		ifeq ($(UNAME_P),armv7l)
			LDLIBS += -lEGL -lGLESv2
			CPPFLAGS += -DGLES
		else
			LDLIBS += -lGLEW -lGL
		endif
	endif
	ifeq ($(UNAME),Darwin)
		LDLIBS += -framework OpenGL
		CXXFLAGS += -DOS_OSX
	endif
endif

# Generated variables
OBJS = $(CXXSRC:.cpp=.o)
DEPS = $(CXXSRC:.cpp=.d)

.PHONY: all run clean

all: $(SONAME)
$(SONAME): $(OBJS)
	$(LINK.o) $^ $(LOADLIBES) $(LDLIBS) -o $@
-include $(DEPS)

clean:
	rm -f $(OBJS) $(DEPS) $(EXE)

lint:
	find . \( -regex '.*\.[vgf]s' -or -regex '.*\.[ch]\(pp\)*' \) -exec clang-format -i '{}' \;
	git status --porcelain | grep -e "^ M" && exit 1 || exit 0
build: all
test: $(EXE)
	@echo "Tests"
host:
	@echo "Host"
bundle: $(ARTIFACT)

