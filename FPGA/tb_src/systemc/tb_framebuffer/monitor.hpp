#pragma once

#include "systemc.h"

SC_MODULE(Monitor) {
    SC_CTOR(Monitor) {
        SC_METHOD(ramEmulator);
        sensitive << ram_addr;
        SC_CTHREAD(continuousCycleCount, clk33.pos());
        SC_CTHREAD(storeOutputData, clk33.pos());
        SC_CTHREAD(runTests, clk33.pos());
        SC_CTHREAD(checkDataIntegrity, clk33.pos());
    }

    sc_in<bool> clk33;
    sc_out<bool> nrst;

    // Signal indicating when a whole slice has been sent
    sc_in<bool> sync;
    // Serial data sent over the 30 drivers
    sc_in<unsigned int> data;

    sc_in<unsigned int> ram_addr;
    sc_out<unsigned int> ram_data;

    // Position of the rotary panel (256 positions)
    sc_out<unsigned int> enc_position;
    sc_out<bool> enc_sync;

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
     * continuousCycleCount is a CTHREAD that keeps incrementing cycleCount
     * until it reaches 512. This counter is the base of synchronisation for
     * all other implemented threads/methods, since the framebuffer is 
     * supposed to be synchronised on 512 cycles.
     */
    void continuousCycleCount();

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

    void runTests();

    private:

    /* 
     * numberOfolumnsRead keeps track of the the number of 512-bit wide
     * cycles passed. Its value is 0 only during the first cycle of this 
     * kind, which indicates that the first buffer is being written and that
     * no relevant data is output from the framebuffer.
     */
    int numberOfColumnsRead;
    
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
};
