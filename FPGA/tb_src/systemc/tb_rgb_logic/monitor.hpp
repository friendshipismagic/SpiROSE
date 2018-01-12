#pragma once

#include <systemc.h>
#include <verilated.h>

#include "driver.hpp"

constexpr int FRAME_WIDTH = 40;
constexpr int FRAME_HEIGHT = 48;
constexpr int NUMBER_OF_FRAME = 256;

SC_MODULE(Monitor) {
    SC_CTOR(Monitor) : nrst("nrst") {
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
    void sendFrame(int nb_frame, int width, int height);
    void checkRAM();
    uint32_t value(uint32_t k, uint32_t x, uint32_t y);
    uint32_t v565(uint32_t v);

    // last checked address in captureRAM
    sc_signal<uint32_t> lastAddr;

    sc_signal<bool> lastVsync;
};
