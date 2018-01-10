#pragma once

#include <systemc.h>
#include <verilated.h>

const sc_time TIME_MUX_CHANGE = sc_time(10, SC_US);

SC_MODULE(Monitor) {
    SC_CTOR(Monitor) : nrst("nrst") {
        SC_THREAD(runTests);
        SC_THREAD(checkMuxOutIsZeroWithoutColumnReady);
    }

    void runTests();
    void checkMuxOutIsZeroWithoutColumnReady();
    void checkMuxOutTimings();
    void checkMuxOutSequence();

    void timeoutThread(sc_time timeout);
    sc_out<bool> nrst;
    sc_out<bool> columnReady;
    sc_in<bool> clk;
    sc_in<uint32_t> muxOut;

    private:
    void sendReset();
};
