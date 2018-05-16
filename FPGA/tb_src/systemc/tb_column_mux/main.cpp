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

#include "Vcolumn_mux.h"

#include "monitor.hpp"
#include "report_handler.hpp"

int sc_main(int argc, char** argv) {
    sc_report_handler::set_handler(report_handler);
    Verilated::commandArgs(argc, argv);

    const sc_time T(15, SC_NS);

    const unsigned int STEPS = 256;
    const unsigned int MAIN_DIV = 4;
    const unsigned int DIV_RATIO = 1;

    sc_time simulationTime = T * STEPS * MAIN_DIV * DIV_RATIO * 1024 * 2;

    sc_clock clk66("clk66", T);
    sc_signal<bool> clk33("clk33");
    sc_signal<bool> nrst("nrst");
    sc_signal<uint32_t> muxOut("muxOut");
    sc_signal<bool> columnReady("column_ready");

    sc_trace_file* traceFile;
    traceFile = sc_create_vcd_trace_file("column_mux");
    sc_trace(traceFile, clk66, "clk_66");
    sc_trace(traceFile, muxOut, "mux_out");
    sc_trace(traceFile, columnReady, "column_ready");
    sc_trace(traceFile, nrst, "nrst");

    Vcolumn_mux dut("column_mux");
    dut.clk(clk66);
    dut.nrst(nrst);
    dut.mux_out(muxOut);
    dut.column_ready(columnReady);

    Monitor monitor("monitor");
    monitor.clk(clk66);
    monitor.nrst(nrst);
    monitor.muxOut(muxOut);
    monitor.columnReady(columnReady);

    nrst = 0;
    sc_start(T);
    sc_start(T);
    nrst = 1;
    while (sc_time_stamp() < simulationTime) {
        if (Verilated::gotFinish()) return 1;
        sc_start(T);
    }

    sc_close_vcd_trace_file(traceFile);

    printReport();

    return errorCount();
}
