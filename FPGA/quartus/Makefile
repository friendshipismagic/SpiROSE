QUARTUS131 ?= /comelec/softs/opt/altera/altera13.1/comelec/quartus_sh

all: compile/12_spi_display

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
	compile/07_rgb_test \
	compile/08_caterpillar_test \
	compile/09_column_mux \
	compile/10_single_led \
	compile/11_hall_sensor \
	compile/12_spi_display

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

compile/07_rgb_test:
	cd 07_rgb_test && $(QUARTUS131) --flow compile rgb_test

compile/08_caterpillar_test:
	cd 08_caterpillar_test && $(QUARTUS131) --flow compile caterpillar_test

compile/09_column_mux:
	cd 09_column_mux && $(QUARTUS131) --flow compile column_mux

compile/10_single_led:
	cd 10_single_led && $(QUARTUS131) --flow compile single_led

compile/11_hall_sensor:
	cd 11_hall_sensor && $(QUARTUS131) --flow compile hall_sensor_test

compile/12_spi_display:
	cd 12_spi_display && $(QUARTUS131) --flow compile spi_display


compile/13_caterpillar_white:
	cd 13_caterpillar_white && $(QUARTUS131) --flow compile caterpillar_white

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
	compile/07_rgb_test \
	compile/08_caterpillar_test \
	compile/09_column_mux \
	compile/10_single_led \
	compile/11_hall_sensor \
	compile/12_spi_display
