EXE = framer

SRCDIR = src
CXXSRC = $(SRCDIR)/main.cpp

CXXFLAGS = -Wall -O2 -g -std=c++14 -iquote$(SRCDIR) -MMD -MP \
           -fdiagnostics-color=auto -DGLM_FORCE_RADIANS
LDLIBS = -lm -lSpiROSE $(shell pkg-config --libs glfw3 assimp)
LDFLAGS = -flto

CC = c++
CXX = c++

OBJS = $(CXXSRC:.cpp=.o)
DEPS = $(CSSSRC:.cpp=.d)

.PHONY: all run clean

all: $(EXE)
$(EXE): $(OBJS)
	$(LINK.o) $^ $(LOADLIBES) $(LDLIBS) -o $@
run: $(EXE)
	./$(EXE)

-include $(DEPS)

clean:
	$(RM) $(DEPS) $(OBJS) $(EXE)

lint:
	find . -regex '.*\.[ch]\(pp\)*' -exec clang-format -i '{}' \;
	git status --porcelain | grep -e "^ M" && exit || exit 0
build: all
test: all

