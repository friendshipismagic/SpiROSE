//
// Copyright (C) 2017-2018 Alexis Bauvin, Vincent Charbonniéras, Clément Decoodt,
// Alexandre Janniaux, Adrien Marcenat
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

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
