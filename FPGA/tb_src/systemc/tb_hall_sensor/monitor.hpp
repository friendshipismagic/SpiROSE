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

SC_MODULE(Monitor) {
    SC_CTOR(Monitor)
        : nrst("nrst"),
          clk("clk"),
          hall1("hall1"),
          hall2("hall2"),
          positionSync("positionSync"),
          sliceCnt("sliceCnt"){
        SC_THREAD(runTests);
    }

    void runTests();

    sc_out<bool> nrst;
    sc_in<bool> clk;

    sc_out<bool> hall1;
    sc_out<bool> hall2;

    sc_in<bool> positionSync;
    sc_in<unsigned int> sliceCnt;

    int positionSyncCounter;
    void checkPositionSync(int value_hall1_to_hall2, int value_hall2_to_hall1);
    void storePositionSync();
    void checkPositionSyncSpacing(int value_hall1_to_hall2);

    private:
    void sendReset();
    void sendHallSignals(int value_hall1_to_hall2, int value_hall2_to_hall1);
};
