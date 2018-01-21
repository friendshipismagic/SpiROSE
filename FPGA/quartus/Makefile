QUARTUS131 = /comelec/softs/opt/altera/altera13.1/comelec/quartus_sh

compile/01_stapl_test:
	cd 01_stapl_test && $(QUARTUS131) --flow compile stapl_test

compile/02_blink_led:
	cd 02_blink_pt6 && $(QUARTUS131) --flow compile blink_pt6

test:
	cd prod && $(QUARTUS131) --flow compile spirose
