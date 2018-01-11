#pragma once

#include <systemc.h>
#include <verilated.h>

#include "driver.hpp"

constexpr int FRAME_WIDTH = 40;
constexpr int FRAME_HEIGHT = 48;

SC_MODULE(Monitor) {
    SC_CTOR(Monitor) : nrst("nrst") {
        ram.resize(8 * FRAME_WIDTH * FRAME_HEIGHT);
        SC_THREAD(runTests);
        SC_CTHREAD(checkRgbEnable, clk.pos());
        SC_CTHREAD(captureRAM, clk.pos());
    }

    void runTests();
    void captureRAM();
    void checkRgbEnable();

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
    void sendFrame();
    void checkRAM(bool zeored);
    void cleanRAM();
    int value(int k, int x, int y);

    std::vector<uint32_t> ram;
};
