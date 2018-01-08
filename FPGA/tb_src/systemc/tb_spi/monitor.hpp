#pragma once

#include <systemc.h>
#include <verilated.h>

SC_MODULE(Monitor) {
    SC_CTOR(Monitor)
        : nrst("nrst"),
          clk("clk"),
          sck("sck"),
          ss("ss"),
          mosi("mosi"),
          miso("miso"),
          newRotationDataAvailable("new_rotation_data_available"),
          configOut("config_out"),
          newConfigAvailable("new_config_available") {
        SC_THREAD(runTests);
    }

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

    void sendCommand(char value);

    int captureValue();

    private:
    void sendReset();
};
