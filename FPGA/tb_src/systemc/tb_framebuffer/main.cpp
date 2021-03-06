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
#include <array>
#include <cstdint>
#include <memory>
#include <sstream>

#include "Vframebuffer.h"
#include "monitor.hpp"
#include "report_handler.hpp"

void tb_report_handler(const sc_report& report, const sc_actions& actions) {
    if (report.get_process_name()) {
        auto name = std::string(report.get_process_name());
        auto it = name.find("monitor.framebuffer");
        std::string allowedName = "monitor.framebuffer_1.";
        if (it != std::string::npos &&
            name.substr(0, allowedName.size()) != allowedName)
            return;
    }
    report_handler(report, actions);
}

int sc_main(int argc, char** argv) {
    sc_report_handler::set_handler(tb_report_handler);
    Verilated::commandArgs(argc, argv);

    const sc_time T(15, SC_NS);

    const unsigned int STEPS = 256;
    const unsigned int MAIN_DIV = 4;
    const unsigned int DIV_RATIO = 1;

    sc_time simulationTime = T * STEPS * MAIN_DIV * DIV_RATIO * 64 * 2;

    sc_clock clk("clk", T);
    sc_signal<bool> nrst("nrst");
    sc_signal<unsigned int> data("data");
    sc_signal<bool> stream_ready("stream_ready");
    sc_signal<bool> driver_ready("driver_ready");
    sc_signal<bool> position_sync("position_sync");
    sc_signal<unsigned int> ram_addr("ram_addr");
    sc_signal<unsigned int> ram_data("ram_data");

    sc_trace_file* traceFile;
    traceFile = sc_create_vcd_trace_file("framebuffer");
    sc_trace(traceFile, clk, "clk");
    sc_trace(traceFile, nrst, "nrst");
    sc_trace(traceFile, data, "data");
    sc_trace(traceFile, stream_ready, "stream_ready");
    sc_trace(traceFile, driver_ready, "driver_ready");
    sc_trace(traceFile, position_sync, "position_sync");
    sc_trace(traceFile, ram_addr, "ram_addr");
    sc_trace(traceFile, ram_data, "ram_data");

    Vframebuffer dut("framebuffer");
    dut.clk(clk);
    dut.nrst(nrst);
    dut.data(data);
    dut.stream_ready(stream_ready);
    dut.driver_ready(driver_ready);
    dut.position_sync(position_sync);
    dut.ram_addr(ram_addr);
    dut.ram_data(ram_data);

    Monitor monitor("monitor");
    monitor.clk(clk);
    monitor.nrst(nrst);
    monitor.stream_ready(stream_ready);
    monitor.driver_ready(driver_ready);
    monitor.position_sync(position_sync);
    monitor.data(data);
    monitor.ram_addr(ram_addr);
    monitor.ram_data(ram_data);
    sc_trace(traceFile, monitor.cycleCounter, "cycleCounter");

    while (sc_time_stamp() < simulationTime) {
        if (Verilated::gotFinish()) return 1;
        sc_start(T);
    }

    sc_close_vcd_trace_file(traceFile);

    printReport();

    return errorCount();
}
