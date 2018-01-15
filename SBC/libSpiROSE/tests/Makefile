TESTS = cube cube_view cube_red cube_view_red cube_dual cube_dual_view

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
	@echo "Running test $^ ..."
	./$^
	$(MAKE) --no-print-directory $^-diff.png
	@echo "Success!"

%-diff.png: %.png %-ref.png
	compare -metric AE $^ $@; code=$$?; echo; exit $$code

# Test-specific targets
%_red-ref.png: %-ref.png
	convert $^ -fill red -opaque white $@

# Interlace test
%_wide.png: %.png
	convert $^ -sample 200%x100%! $@
%_comb.png: %_1_wide.png %_2_wide.png
	convert $^ -fx 'i % 2 ? u : v' $@
cube_interlace_1.png: cube_interlace.png
	convert $^[40x48+0+96] $@
cube_interlace_2.png: cube_interlace.png
	convert $^[40x48+0+288] $@
cube_interlace-run: cube_interlace
	@echo "Running test $^ ..."
	./$^
	$(MAKE) --no-print-directory $^_comb-diff.png
	@echo "Success!"

clean:
	$(RM) $(TESTS:=_test.o) $(TESTS:=_test.d) main.d main.o $(TESTS)
	$(RM) *-diff.png $(TESTS:=.png)
	$(RM) cube_interlace_{1,2}.png

lint:
	find . \( -regex '.*\.[vf]s' -or -regex '.*\.[ch]\(pp\)*' \) -exec clang-format -i '{}' \;
	git status --porcelain | grep -e "^ M" && exit 1 || exit 0
build: all
test: $(EXE)
	@echo "Tests"
host:
	@echo "Host"
bundle: $(ARTIFACT)

