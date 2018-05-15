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

const sc_time TIME_MUX_CHANGE = sc_time(10, SC_US);

SC_MODULE(Monitor) {
    SC_CTOR(Monitor) : nrst("nrst") {
        SC_THREAD(runTests);
        SC_THREAD(checkMuxOutIsZeroWithoutColumnReady);
        SC_CTHREAD(sendColumnReady, clk.pos());
    }

    void runTests();
    void checkMuxOutIsZeroWithoutColumnReady();
    void checkMuxOutTimings();
    void checkMuxOutSequence();
    void sendColumnReady();

    void timeoutThread(sc_time timeout);
    sc_out<bool> nrst;
    sc_out<bool> columnReady;
    sc_in<bool> clk;
    sc_in<uint32_t> muxOut;
};
