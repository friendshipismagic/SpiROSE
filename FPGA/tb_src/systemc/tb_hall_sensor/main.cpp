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

#include <systemc.h>
#include <verilated.h>

#include "Vhall_sensor.h"

#include "monitor.hpp"
#include "report_handler.hpp"

int sc_main(int argc, char** argv) {
    sc_report_handler::set_handler(report_handler);
    Verilated::commandArgs(argc, argv);

    const sc_time T(30, SC_NS);

    const unsigned int STEPS = 256;
    const unsigned int MAIN_DIV = 4;
    const unsigned int DIV_RATIO = 1;

    sc_time simulationTime = T * STEPS * MAIN_DIV * DIV_RATIO * 1024 * 2;

    sc_clock clk("clk", T);
    sc_signal<bool> nrst("nrst");

    sc_signal<bool> hall1;
    sc_signal<bool> hall2;
    sc_signal<bool> positionSync;
    sc_signal<unsigned int> sliceCnt;
    sc_signal<unsigned int> speedData;

    sc_trace_file* traceFile;
    traceFile = sc_create_vcd_trace_file("sensor");
    sc_trace(traceFile, clk, "clk");
    sc_trace(traceFile, nrst, "nrst");
    sc_trace(traceFile, hall1, "hall_1");
    sc_trace(traceFile, hall2, "hall_2");
    sc_trace(traceFile, sliceCnt, "slice_cnt");
    sc_trace(traceFile, positionSync, "position_sync");
    sc_trace(traceFile, speedData, "speedData");

    Vhall_sensor dut("hall_sensor");
    dut.clk(clk);
    dut.nrst(nrst);
    dut.hall_1(hall1);
    dut.hall_2(hall2);
    dut.slice_cnt(sliceCnt);
    dut.position_sync(positionSync);
    dut.speed_data(speedData);

    Monitor monitor("monitor");
    monitor.clk(clk);
    monitor.nrst(nrst);
    monitor.hall1(hall1);
    monitor.hall2(hall2);
    monitor.sliceCnt(sliceCnt);
    monitor.positionSync(positionSync);

    while (sc_time_stamp() < simulationTime) {
        if (Verilated::gotFinish()) return 1;
        sc_start(T);
    }

    sc_close_vcd_trace_file(traceFile);

    printReport();

    return errorCount();
}
