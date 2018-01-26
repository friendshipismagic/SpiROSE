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
          debugData("debug_data"),
          configuration("configuration"),
          newConfigAvailable("new_config_available"),
          rgbEnable("rgb_enable"),
          mux("mux") {
        driver_data.reserve(30);
        for (int i = 0; i < driver_data.size(); i++)
            driver_data[i] = std::make_unique<sc_in<uint64_t>>(
                ("driver_data[" + std::to_string(i) + "]").c_str());
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
    sc_out<uint32_t> debugData;
    sc_in<uint64_t> configuration;
    sc_in<bool> newConfigAvailable;
    sc_in<bool> rgbEnable;
    sc_in<uint32_t> mux;
    std::vector<std::unique_ptr<sc_in<uint64_t>>> driver_data;

    void sendCommand(char value);
    void handleSck();
    void handleSs();

    unsigned char captureValue();

    private:
    void sendReset();
    sc_signal<bool> enableSck;
};
