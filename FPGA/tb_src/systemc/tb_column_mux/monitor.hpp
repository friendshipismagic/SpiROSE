#pragma once

#include <systemc.h>
#include <verilated.h>

const sc_time TIME_MUX_CHANGE = sc_time(10, SC_US);

SC_MODULE(Monitor) {
    SC_CTOR(Monitor) : nrst("nrst") { SC_CTHREAD(runTests, clk.pos()); }

    void runTests();
    void checkMuxOutTimings();
    sc_out<bool> nrst;
    sc_in<bool> clk;
    sc_in<uint32_t> muxOut;

    private:
    void sendReset();
};
