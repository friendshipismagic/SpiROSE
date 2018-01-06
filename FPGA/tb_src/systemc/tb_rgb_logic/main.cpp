#include <systemc.h>
#include <verilated.h>

#include "Vrgb_logic.h"

#include "monitor.hpp"
#include "report_handler.hpp"

int sc_main(int argc, char** argv) {
    sc_report_handler::set_handler(report_handler);
    Verilated::commandArgs(argc, argv);

    // TODO: change clock period to the RGB's one
    const sc_time T(30, SC_NS);

    const unsigned int STEPS = 256;
    const unsigned int MAIN_DIV = 4;
    const unsigned int DIV_RATIO = 1;

    sc_time simulationTime = T * STEPS * MAIN_DIV * DIV_RATIO * 1024 * 2;

    sc_clock clk("clk", T);
    sc_signal<bool> nrst("nrst");
    sc_signal<bool> hsync("hsync");
    sc_signal<bool> vsync("vsync");
    sc_signal<bool> write_enable("write_enable");
    sc_signal<uint32_t> rgb("rgb");
    sc_signal<uint32_t> ram_addr("ram_addr");
    sc_signal<uint32_t> ram_data("ram_data");

    sc_trace_file* traceFile;
    traceFile = sc_create_vcd_trace_file("rgb_logic");
    sc_trace(traceFile, clk, "clk");

    Vrgb_logic dut("rgb_logic");
    dut.rgb_clk(clk);
    dut.nrst(nrst);
    dut.rgb(rgb);
    dut.hsync(hsync);
    dut.vsync(vsync);
    dut.ram_addr(ram_addr);
    dut.ram_data(ram_data);
    dut.write_enable(write_enable);

    Monitor monitor("monitor");
    monitor.clk(clk);
    monitor.nrst(nrst);

    while (sc_time_stamp() < simulationTime) {
        if (Verilated::gotFinish()) return 1;
        sc_start(T);
    }

    sc_close_vcd_trace_file(traceFile);

    printReport();

    return errorCount();
}
