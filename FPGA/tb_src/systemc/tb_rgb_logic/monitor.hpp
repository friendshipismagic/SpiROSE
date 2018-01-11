#pragma once

#include <systemc.h>
#include <verilated.h>

#include "driver.hpp"

SC_MODULE(Monitor) {
    SC_CTOR(Monitor) : nrst("nrst") { SC_CTHREAD(runTests, clk.pos()); }

    void runTests();

    sc_out<bool> nrst;
    sc_in<bool> clk;

    sc_out<uint32_t> rgb;
    sc_out<bool> hsync;
    sc_out<bool> vsync;

    sc_in<uint32_t> ramAddr;
    sc_in<uint32_t> ramData;
    sc_in<bool> writeEnable;

    sc_out<bool> rgbEnable;
    sc_in<bool> streamReady;

    private:
    void sendReset();
};
