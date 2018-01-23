QUARTUS131 = /comelec/softs/opt/altera/altera13.1/comelec/quartus_sh

compile/01_stapl_test:
	cd 01_stapl_test && $(QUARTUS131) --flow compile stapl_test

compile/02_blink_led:
	cd 02_blink_pt6 && $(QUARTUS131) --flow compile blink_pt6

compile/03_pt6_clock:
	cd 03_pt6_clock && $(QUARTUS131) --flow compile pt6_clock

compile/05_spi_test:
	cd 05_spi_test && $(QUARTUS131) --flow compile spi_test

test:
	cd prod && $(QUARTUS131) --flow compile spirose
