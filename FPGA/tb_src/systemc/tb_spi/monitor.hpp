#pragma once

#include <systemc.h>
#include <verilated.h>

SC_MODULE(Monitor) {
    SC_CTOR(Monitor) : nrst("nrst") { SC_CTHREAD(runTests, clk.pos()); }

    void runTests();

    sc_out<bool> nrst;
    sc_in<bool> clk;

    private:
    void sendReset();
};
