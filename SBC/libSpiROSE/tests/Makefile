TESTS = sample

GCC_COLOR_MODE = auto
CXXFLAGS = -Wall -O2 -g -std=c++14 -MMD -MP \
           -fdiagnostics-color=$(GCC_COLOR_MODE) -DGLM_FORCE_RADIANS

LDLIBS = -lm -lSpiROSE $(shell pkg-config --libs glfw3 2> /dev/null)
LDFLAGS = -flto

CC = c++
CXX = c++

.PHONY: all run clean

all: $(TESTS)
%: %_test.o main.o
	$(LINK.o) $^ $(LOADLIBES) $(LDLIBS) -o $@
run: $(TESTS:=-run)
%-run: %
	./$^

clean:
	rm -f $(TESTS:=.o) $(TESTS:=.d) main.d main.o $(TESTS)

lint:
	find . \( -regex '.*\.[vf]s' -or -regex '.*\.[ch]\(pp\)*' \) -exec clang-format -i '{}' \;
	git status --porcelain | grep -e "^ M" && exit 1 || exit 0
build: all
test: $(EXE)
	@echo "Tests"
host:
	@echo "Host"
bundle: $(ARTIFACT)

