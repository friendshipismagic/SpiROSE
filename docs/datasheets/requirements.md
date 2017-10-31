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
 - RGB input: 2 pixels/clock, 24b per pixel, 48 I/O for RGB + 1 I/O for clock.

Total: 79 I/O
