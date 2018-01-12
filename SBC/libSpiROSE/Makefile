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


LDLIBS = -lm $(shell pkg-config --libs glfw3 2> /dev/null)
LDFLAGS = -flto -shared -Wl,-soname,$(SONAME)

UNAME_P := $(shell uname -p)
ifeq ($(UNAME_P),armv7l)
	LDLIBS += -lEGL -lGLESv2
	CPPFLAGS += -DGLES
else
	LDLIBS += -lGLEW -lGL
endif

CC = c++
CXX = c++

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

