#include <systemc.h>
#include <verilated.h>

#include "Vclock_lse.h"
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
    sc_signal<bool> enable("enable");
    sc_signal<bool> framebufferSync("framebufferSync");

    sc_trace_file* traceFile;
    traceFile = sc_create_vcd_trace_file("column_mux");
    sc_trace(traceFile, clk66, "clk_66");
    sc_trace(traceFile, clk33, "clk_33");
    sc_trace(traceFile, muxOut, "mux_out");
    sc_trace(traceFile, enable, "enable");
    sc_trace(traceFile, framebufferSync, "framebufferSync");

    Vclock_lse clock_lse("clock_lse");
    clock_lse.nrst(nrst);
    clock_lse.clk_lse(clk33);
    clock_lse.clk_hse(clk66);

    Vcolumn_mux dut("column_mux");
    dut.clk_33(clk33);
    dut.nrst(nrst);
    dut.mux_out(muxOut);
    dut.enable(enable);
    dut.framebuffer_sync(framebufferSync);

    Monitor monitor("monitor");
    monitor.clk(clk66);
    monitor.nrst(nrst);
    monitor.muxOut(muxOut);
    monitor.enable(enable);
    monitor.framebufferSync(framebufferSync);

    while (sc_time_stamp() < simulationTime) {
        if (Verilated::gotFinish()) return 1;
        sc_start(T);
    }

    sc_close_vcd_trace_file(traceFile);

    printReport();

    return errorCount();
}
