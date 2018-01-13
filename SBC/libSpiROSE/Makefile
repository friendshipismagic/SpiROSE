SONAME = libSpiROSE.so
SRCDIR = src
CXXSRC = $(SRCDIR)/spirose.cpp \
         $(SRCDIR)/context.cpp \
         $(SRCDIR)/object.cpp
GLSLSRC = $(SRCDIR)/shader/voxel.vss \
          $(SRCDIR)/shader/voxel.fss \
          $(SRCDIR)/shader/synth.vss \
          $(SRCDIR)/shader/synth.fss \
          $(SRCDIR)/shader/view.vss \
          $(SRCDIR)/shader/view.fss

GCC_COLOR_MODE = auto
CXXFLAGS = -Wall -O2 -g -std=c++14 -iquote$(SRCDIR) -MMD -MP \
           -fdiagnostics-color=$(GCC_COLOR_MODE) -DGLM_FORCE_RADIANS -fpic

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

# Declare this target as a default for context.o, to be overriden by gcc's
# context.d
src/context.o: src/context.cpp $(GLSLSRC)

-include $(DEPS)

# Adds 'R"(' and ')"' to the file to make it compatible with C++ raw strings
%.vss: %.vs
	./rawify $^ $@
%.fss: %.fs
	./rawify $^ $@

clean:
	rm -f $(OBJS) $(DEPS) $(EXE) $(GLSLSRC)

lint:
	find . \( -regex '.*\.[vf]s' -or -regex '.*\.[ch]\(pp\)*' \) -exec clang-format -i '{}' \;
	git status --porcelain | grep -e "^ M" && exit 1 || exit 0
build: all
test: $(EXE)
	@echo "Tests"
host:
	@echo "Host"
bundle: $(ARTIFACT)

