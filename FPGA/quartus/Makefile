QUARTUS131 = /comelec/softs/opt/altera/altera13.1/comelec/quartus_sh

bundle: compile
	mkdir -p stapl
	cp */*/*.jbc stapl/

compile: \
	compile/01_stapl_test \
	compile/02_blink_led \
	compile/03_pt6_clock \
	compile/04_rgb_pll \
	compile/05_memory \
	compile/06_spi_test \
	compile/07_rgb_test

compile/01_stapl_test:
	cd 01_stapl_test && $(QUARTUS131) --flow compile stapl_test

compile/02_blink_led:
	cd 02_blink_pt6 && $(QUARTUS131) --flow compile blink_pt6

compile/03_pt6_clock:
	cd 03_pt6_clock && $(QUARTUS131) --flow compile pt6_clock

compile/04_rgb_pll:
	cd 04_rgb_pll && $(QUARTUS131) --flow compile rgb_pll

compile/05_memory:
	cd 05_memory && $(QUARTUS131) --flow compile memory

compile/06_spi_test:
	cd 06_spi_test && $(QUARTUS131) --flow compile spi_test

compile/07_single_led:
	cd 07_single_led && $(QUARTUS131) --flow compile single_led

compile/07_rgb_test:
	cd 07_rgb_test && $(QUARTUS131) --flow compile rgb_test

test:
	cd prod && $(QUARTUS131) --flow compile spirose

clean:
	$(RM) stapl */output_files -r

clean-all: clean
	$(RM) */board */db */incremental_db */output_files */simulation */timing -rf

.PHONY: bundle compile clean clean-all \
	compile/01_stapl_test \
	compile/02_blink_led \
	compile/03_pt6_clock \
	compile/04_rgb_pll \
	compile/05_memory \
	compile/06_spi_test \
	compile/07_rgb_test
