#include <systemc.h>
#include <verilated.h>

#include "monitor.hpp"

static uint8_t fbOutput[30][9][48];

void Monitor::reset() {
    nrst = 0;
    wait(clk33.posedge());
    nrst = 1;
}

void Monitor::continuousCycleCount() {
    while(1) {
        if (!nrst) {
            cycleCounter = 0; 
        }
        else {
            if (cycleCounter == 512) {
                cycleCounter = 0;
            }
            cycleCounter++;
        }
        wait();
    }
}

void Monitor::storeOutputData() {
    while(1) {
        if (!nrst) {
            // Reset the value of the output test array
            int i, j, k;
            for (i = 0; i < 30; i++) {
                for (j = 0; j < 9; j++) {
                    for (k = 0; k < 48; k++) {
                        fbOutput[i][j][k] = 0;
                    }
                }
            }
        }
        else if (cycleCounter >= 0 
                    && cycleCounter < 440
                    && cycleCounter != 48
                    && cycleCounter != 97
                    && cycleCounter != 146
                    && cycleCounter != 195
                    && cycleCounter != 244
                    && cycleCounter != 293
                    && cycleCounter != 342
                    && cycleCounter != 391) {
            for (int i = 0; i < 30; i++) {
                fbOutput[i][cycleCounter/49][cycleCounter%49] = (data >> i) & 0x1;
            }
        }
        wait();
    }
}

void Monitor::checkWRTGSBlanking() {
    while (1) {
        if (cycleCounter == 48 && cycleCounter == 48+49 /* ... */) {

        }
        wait();
    }
}


/* 
 * The aims of this testing method is to check that the data
 * that is output by the framebuffer module is correct,
 * relatively to the frames structure and the order in which
 * the data is meant to be ouput aka in poker mode.
 * The idea of the framebuffer is that it reads 30 16-bit wide
 * data from RAM and at the next cycle outputs it.
 * 
 * Besides, since the pin assignment for the drivers was changed,
 * look-up tables need to be implemented in the framebuffer module
 * so as to modify the order of the data half words between the moment 
 * they are read in RAM and they are sent to the driver controller.
 * Taking the led panel schematic notations, there are two different
 * driver pin assignments for {UB0, {UB1, UB2}}. The 16-bit data is 
 * thus changed depending of which driver it corresponds to.
 * 
 * The signals that are used are data and sync.
 */
void Monitor::checkDataIntegrity() {

}



/* 
 * To emulate the RAM, we simply have an emulator that gives
 * back data as a function of the address to the framebuffer.
 * It will be tested, to be sure that the framebuffer correctly
 * sends data forward to the driver controller in poker mode
 * and in the right order.
 *
 * The real RAM structure is as follows:
 * The µblocks are stored one after another (µblock0, ... , µblock18)
 * Each µblock has 80*46 pixels, each pixel being 16-bit wide, aka RGB565.
 * Poker mode implies that the pixels are cut and sent to each driver
 * in the following order:
 * B15[n] || G15[n] || R15[n] || ... || B0[n] || G0[n] || R0[n]
 */
void Monitor::ramEmulator() {
    ram_data = ram_addr % (1 << 16);
}
