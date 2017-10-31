Requirements definition for components
======================================

# LEDs

RoseAce uses their LEDs at 35% duty cycle, we don't have to be that powerful

# LED Drivers

Drivers must support multiplexing.
Bandwidth calculations todo for dimensionning clock and max multiplexing level.

# FPGA

We must bufferize at least 1 image, so around 9k pixels. There must be a memory
of at least 27kb.

I/O Count:

 - LED drivers: SCK+MOSI per driver, around 15 drivers = 30 I/O.
 - RGB input: 2 pixels/clock, 48 I/O for RGB + 7 I/O for CTL + 1 I/O for clock.

Total: 86 I/O

# HDMI to RGB

No HDCP in the chip, so that we don't have NDA, agreements or stuff like this to
use the chip.

Without optimisation, approx. 4Mpx@30fps, so 800x600px@30fps is good enough.
