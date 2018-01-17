#include <systemc.h>
#include <verilated.h>

#include "Vhall_sensor.h"

#include "monitor.hpp"
#include "report_handler.hpp"

int sc_main(int argc, char** argv) {
    sc_report_handler::set_handler(report_handler);
    Verilated::commandArgs(argc, argv);

    // TODO: choose a clock closer to the reality for spi
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

    sc_trace_file* traceFile;
    traceFile = sc_create_vcd_trace_file("sensor");
    sc_trace(traceFile, clk, "clk");
    sc_trace(traceFile, nrst, "nrst");
    sc_trace(traceFile, hall1, "hall_1");
    sc_trace(traceFile, hall2, "hall_2");
    sc_trace(traceFile, sliceCnt, "slice_cnt");
    sc_trace(traceFile, positionSync, "position_sync");


    Vhall_sensor dut("hall_sensor");
    dut.clk(clk);
    dut.nrst(nrst);
    dut.hall_1(hall1);
    dut.hall_2(hall2);
    dut.slice_cnt(sliceCnt);
    dut.position_sync(positionSync);

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
