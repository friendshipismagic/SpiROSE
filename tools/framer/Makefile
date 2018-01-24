EXE = framer

SRCDIR = src
CXXSRC = $(SRCDIR)/main.cpp

LIBSPIROSE ?= ../../SBC/libSpiROSE

CXXFLAGS = -Wall -O2 -g -std=c++14 -iquote$(SRCDIR) -MMD -MP \
           -fdiagnostics-color=auto -DGLM_FORCE_RADIANS \
           -I$(LIBSPIROSE)/src
LDLIBS = -lm -lSpiROSE $(shell pkg-config --libs glfw3 assimp)
LDFLAGS = -flto -L$(LIBSPIROSE)

CC = c++
CXX = c++

OBJS = $(CXXSRC:.cpp=.o)
DEPS = $(CSSSRC:.cpp=.d)

.PHONY: all run clean

all: $(EXE)
$(EXE): $(OBJS)
	$(LINK.o) $^ $(LOADLIBES) $(LDLIBS) $(LDFLAGS) -o $@
run: $(EXE)
	LD_LIBRARY_PATH=$(LIBSPIROSE) ./$(EXE)

-include $(DEPS)
-include tests/tests.mk

clean:
	$(RM) $(DEPS) $(OBJS) $(EXE)

lint:
	find . -regex '.*\.[ch]\(pp\)*' -exec clang-format -i '{}' \;
	git status --porcelain | grep -e "^ M" && exit || exit 0
build: all
test: all
	export DISPLAY=:10; \
		Xvfb $$DISPLAY -screen $$DISPLAY 1280x720x24 +extension GLX & \
		sleep 2; \
		$(MAKE) clean-tests; \
		DISPLAY=:10 $(MAKE) run-tests; \
		code=$$?; \
		kill %1; \
		wait %1; \
		exit $$code

