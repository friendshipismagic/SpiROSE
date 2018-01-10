#pragma once

#include "systemc.h"

SC_MODULE(Monitor) {
    SC_CTOR(Monitor) {
        SC_METHOD(ramEmulator);
        sensitive << ram_addr;
        SC_CTHREAD(storeOutputData, clk33.pos());
        SC_CTHREAD(runTests, clk33.pos());
        SC_CTHREAD(checkDataIntegrity, clk33.pos());
    }

    sc_in<bool> clk33;
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
     * Description of the operations needed for a single slice:
     * There a 8 identical 512-cycle-long processes thar take place
     * for a slide. The number is 8 since we have a 8-multiplexing.
     * During the i-th 512-cycle-long process, the framebuffer outputs
     * the i-th multiplexed LED data in poker mode during the first
     * 440 cycles, with a 1-cycle blanking during each 48-bit wide
     * output data, corresponding to the required latency for the
     * driver WRTGS command. The remaining 72 cycles are needed to
     * have the 512 GCLK cycles.
     */

    /*
     * Function that stores the output data of the framebuffer during
     * the period it is emitted, aka between cycleCounter=0 and 440.
     */
    void storeOutputData();

    void checkDataIntegrity();

    void ramEmulator();

    /*
     * Check that every time a 48-bit wide section is transmitted, a
     * blanking cycle is inserted to fit the timing constraints
     * of the driver. This test can be achieved by verifying that the
     * data output remains stable over the 2 concerned clock cycles.
     */
    void checkWRTGSBlanking();

    void cycleSync();

    void runTests();

    private:

    /*
     * cycleCounter is a variable that monitors the location inside
     * each 512-bit wide process.
     */
    int cycleCounter;

    // Indicates the current multiplexing number (from 0 to 7)
    int currentMultiplexing;

    void reset();

    /*
     * Returns 1 if the cycle number corresponds to a blanking cycle needed
     * for a WRTGS command, else 0
     */
    int isWRTGSBlankingCycle(int cycle);

    void singleFrameCheck(int cycleNumber);
};
