# Simple tests that generate a PNG to be compared to a reference ont
# Requirements: <test name>_test.cpp <test name>-ref.png
# Outputs: <test name>.test.png
#    (or): <binary name>.png
# No extra makefile targets needed
TESTS = cube cube_view cube_red cube_view_red cube_dual cube_dual_view
# Trickier tests, needing post-processing of the output image. The
# post-processed image is to be compared to a reference one.
# Requirements: <test name>_test.cpp <test name>-ref.png
# Outputs: <test name>.test.png
#    (or): <binary name>.png
# However, targets needs to be defined to generate <test name>-comb.png from
# <test name>.test.png
# Also, if intermediate PNG files are generated, add them to the
# POST_INTERMEDIATE variable for the clean target.
TESTS_POST = cube_interlace

GCC_COLOR_MODE = auto
CXXFLAGS = -Wall -O2 -g -std=c++14 -MMD -MP \
           -fdiagnostics-color=$(GCC_COLOR_MODE) -DGLM_FORCE_RADIANS

LDLIBS = -lm -lSpiROSE $(shell pkg-config --libs glfw3 2> /dev/null)
LDFLAGS = -flto

CC = c++
CXX = c++

.PHONY: all run clean

all: $(TESTS:=.test) $(TESTS_POST:=.test)
%.test: %_test.o main.o
	$(LINK.o) $^ $(LOADLIBES) $(LDLIBS) -o $@
run: $(TESTS:=-diff.png) $(TESTS_POST:=-comb-diff.png)

%-diff.png: %.test.png %-ref.png
	compare -metric AE $^ $@; code=$$?; echo; exit $$code
%.test.png: %.test
	./$^

# Test with post-processing
%-comb-diff.png: %-comb.png %-ref.png
	compare -metric AE $^ $@; code=$$?; echo; exit $$code

# Test-specific targets
%_red-ref.png: %-ref.png
	convert $^ -fill red -opaque white $@

# Interlace test
POST_INTERMEDIATE += cube_interlace_1 png cube_interlace_2
cube_interlace_1.png: cube_interlace.test.png
	convert $^[40x48+0+96] -sample 200%x100%! $@
cube_interlace_2.png: cube_interlace.test.png
	convert $^[40x48+0+288] -sample 200%x100%! $@
cube_interlace-comb.png: cube_interlace_1.png cube_interlace_2.png
	convert $^ -fx 'i % 2 ? u : v' $@

clean:
	@# Binary files
	$(RM) main.d main.o
	$(RM) $(TESTS:=_test.o) $(TESTS:=_test.d) $(TESTS:=.test)
	$(RM) $(TESTS_POST:=_test.o) $(TESTS_POST:=_test.d) $(TESTS_POST:=.test)
	@# Simple tests output PNGs
	$(RM) $(TESTS:=.test.png) $(TESTS:=-diff.png)
	@# Tests with post-processing output PNGs
	$(RM) $(TESTS_POST:=.test.png) $(TESTS_POST:=-comb.png) $(TESTS_POST:=-comb-diff.png) $(POST_INTERMEDIATE:=.png)

lint:
	find . \( -regex '.*\.[vf]s' -or -regex '.*\.[ch]\(pp\)*' \) -exec clang-format -i '{}' \;
	git status --porcelain | grep -e "^ M" && exit 1 || exit 0
build: all
test: $(EXE)
	@echo "Tests"
host:
	@echo "Host"
bundle: $(ARTIFACT)

