#pragma once

#include <systemc.h>
#include <verilated.h>

SC_MODULE(Monitor) {
    SC_CTOR(Monitor) : nrst("nrst") { SC_CTHREAD(runTests, clk.pos()); }

    void runTests();

    sc_out<bool> nrst;
    sc_in<bool> clk;
    sc_out<bool> sck;

    sc_out<bool> ss;
    sc_out<bool> mosi;
    sc_in<bool> miso;

    sc_out<bool> newRotationDataAvailable;
    sc_in<uint64_t> configOut;
    sc_in<bool> newConfigAvailable;

    void generateSck(int count);
    void checkValue(int count, bool value);

    private:
    void sendReset();
};
