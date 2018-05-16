//
// Copyright (C) 2017-2018 Alexis Bauvin, Vincent Charbonniéras, Clément Decoodt,
// Alexandre Janniaux, Adrien Marcenat
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#pragma once

#include "systemc.h"

SC_MODULE(Monitor) {
    SC_CTOR(Monitor) {
        SC_METHOD(ramEmulator);
        sensitive << ram_addr;
        SC_CTHREAD(storeOutputData, clk.pos());
        SC_CTHREAD(runTests, clk.pos());
        SC_CTHREAD(checkDataIntegrity, clk.pos());
        SC_CTHREAD(checkWRTGSBlanking, clk.pos());
    }

    sc_in<bool> clk;
    sc_out<bool> nrst;

    // Signals that enough images has been cached to start displaying frames
    sc_out<bool> stream_ready;
    // Signals that drivers have been configured and are ready to display frames
    sc_out<bool> driver_ready;
    // Signal indicating when a whole slice has been sent
    sc_out<bool> position_sync;

    // Serial data sent over the 30 drivers
    sc_in<unsigned int> data;

    sc_in<unsigned int> ram_addr;
    sc_out<unsigned int> ram_data;
    /*
     * cycleCounter is a variable that monitors the location inside
     * each 512-bit wide process.
     */
    sc_signal<int> cycleCounter;

    /*
     * Function that stores the output data of the framebuffer during
     * the period it is emitted, aka between cycleCounter=0 and 440.
     */
    void storeOutputData();

    // Compare the output of the framebuffer  with a reference
    void checkDataIntegrity();

    // Gives data base on the address
    void ramEmulator();

    /*
     * Check that every time a 48-bit wide section is transmitted, a
     * blanking cycle is inserted to fit the timing constraints
     * of the driver. This test can be achieved by verifying that the
     * data output remains stable over the 2 concerned clock cycles.
     */
    void checkWRTGSBlanking();

    void cycleCounterGenerator();

    void runTests();

    private:

    // Indicates the current multiplexing number (from 0 to 7)
    int currentMultiplexing;
    // ram address offset to read the correct slice
    int ramBaseAddress;

    void reset();

    /*
     * Returns 1 if the cycle number corresponds to a blanking cycle needed
     * for a WRTGS command, else 0
     */
    int isWRTGSBlankingCycle(int cycle);

    // Generate position_sync and updateramBaseAddress
    void frameInputControlGenerator(int frameNumber, int waitForNextSliceCycles);

    // Generate a data depending on the given address
    unsigned int dataGenerator(unsigned int addr);
};
