SONAME = libSpiROSE.so
SRCDIR = src
CXXSRC = $(SRCDIR)/spirose.cpp \
         $(SRCDIR)/context.cpp \
         $(SRCDIR)/object.cpp \
         $(SRCDIR)/utils.cpp
GLSLSRC = $(SRCDIR)/shader/voxel.vss \
          $(SRCDIR)/shader/voxel.fss \
          $(SRCDIR)/shader/synth.vss \
          $(SRCDIR)/shader/synth.fss \
          $(SRCDIR)/shader/view.vss \
          $(SRCDIR)/shader/view.fss

GCC_COLOR_MODE = auto
CXXFLAGS = -Wall -O2 -g -std=c++14 -iquote$(SRCDIR) -MMD -MP \
           -fdiagnostics-color=$(GCC_COLOR_MODE) -DGLM_FORCE_RADIANS -fpic

LDLIBS = -lm $(shell pkg-config --libs glfw3 2> /dev/null) \
         $(shell pkg-config --libs libpng 2> /dev/null)
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

.PHONY: all run clean install

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

LIBDIR = /usr/lib
INCDIR = /usr/include
install: $(SONAME)
	install -Cd $(INCDIR)/spirose
	install -C -m 644 src/*.h $(INCDIR)/spirose/
	install -C -m 755 $(SONAME) $(LIBDIR)/

lint:
	find . \( -regex '.*\.[vf]s' -or -regex '.*\.[ch]\(pp\)*' \) -exec clang-format -i '{}' \;
	git status --porcelain | grep -e "^ M" && exit 1 || exit 0
build: all
test:
	export DISPLAY=:10; \
		Xvfb $$DISPLAY -screen $$DISPLAY 1280x720x24 +extension GLX & \
		sleep 2; \
		pushd tests; \
		make clean; \
		DISPLAY=:10 $(MAKE) run; \
		code=$$?; \
		popd; \
		kill %1; \
		wait %1; \
		exit $$code
host:
	@echo "Host"
bundle: $(SONAME)
	mkdir -p {lib,include}
	$(MAKE) install LIBDIR=lib INCDIR=include

