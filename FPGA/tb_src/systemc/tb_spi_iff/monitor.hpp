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

#include <array>

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
    std::array<sc_in<uint64_t>, 30> driver_data;

    void sendCommand(char value);
    void handleSck();
    void handleSs();

    unsigned char captureValue();

    private:
    void sendReset();
    sc_signal<bool> enableSck;
};
