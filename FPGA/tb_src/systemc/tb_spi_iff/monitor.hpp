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
          valid("valid"),
          rotationData("rotation_data"),
          speedData("speed_data"),
          configuration("configuration"),
          newConfigAvailable("new_config_available") {
        SC_THREAD(runTests);
        SC_THREAD(handleSck);
        SC_THREAD(handleSs);
    }

    void runTests();

    sc_out<bool> nrst;
    sc_in<bool> clk;

    sc_out<bool> sck;
    sc_out<bool> ss;
    sc_out<bool> mosi;
    sc_in<bool> miso;
    sc_in<bool> valid;

    sc_out<uint32_t> rotationData;
    sc_out<uint32_t> speedData;
    sc_in<uint64_t> configuration;
    sc_in<bool> newConfigAvailable;
    sc_in<bool> rgbEnable;

    void sendCommand(char value);
    void handleSck();
    void handleSs();

    unsigned char captureValue();

    private:
    void sendReset();
    sc_signal<bool> enableSck;
};