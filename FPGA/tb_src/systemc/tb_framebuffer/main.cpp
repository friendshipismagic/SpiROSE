#include <systemc.h>
#include <verilated.h>
#include <array>
#include <cstdint>
#include <memory>
#include <sstream>

#include "Vframebuffer.h"
#include "monitor.hpp"

int sc_main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    const sc_time T(30, SC_NS);

    const unsigned int STEPS = 256;
    const unsigned int MAIN_DIV = 4;
    const unsigned int DIV_RATIO = 1;

    sc_time simulationTime = T * STEPS * MAIN_DIV * DIV_RATIO * 1024 * 2;

    sc_clock clk33("clk33", T);
    sc_signal<bool> nrst("nrst");
    sc_signal<unsigned int> data("data");
    sc_signal<bool> sync("sync");
    sc_signal<unsigned int> ram_addr("ram_addr");
    sc_signal<unsigned int> ram_data("ram_data");

    // Encoder position, to be changed with Hall effect sensor info
    sc_signal<unsigned int> enc_position("enc_position");
    sc_signal<bool> enc_sync("enc_sync");

    sc_trace_file* traceFile;
    traceFile = sc_create_vcd_trace_file("driver_controller");
    sc_trace(traceFile, clk33, "clk33");
    sc_trace(traceFile, nrst, "nrst");
    sc_trace(traceFile, data, "data");
    sc_trace(traceFile, sync, "sync");
    sc_trace(traceFile, ram_addr, "ram_addr");
    sc_trace(traceFile, ram_data, "ram_data");
    sc_trace(traceFile, enc_position, "enc_position");
    sc_trace(traceFile, enc_sync, "enc_sync");

    Vframebuffer dut("framebuffer");
    dut.clk_33(clk33);
    dut.nrst(nrst);
    dut.data(data);
    dut.sync(sync);
    dut.ram_addr(ram_addr);
    dut.ram_data(ram_data);
    dut.enc_position(enc_position);
    dut.enc_sync(enc_sync);

    Monitor monitor("monitor");
    monitor.clk33(clk33);
    monitor.nrst(nrst);
    monitor.sync(sync);
    monitor.data(data);
    monitor.ram_addr(ram_addr);
    monitor.ram_data(ram_data);
    monitor.enc_position(enc_position);
    monitor.enc_sync(enc_sync);

    while (sc_time_stamp() < simulationTime) {
        if (Verilated::gotFinish()) return 1;
        sc_start(T);
    }

    sc_close_vcd_trace_file(traceFile);

    return EXIT_SUCCESS;
}
